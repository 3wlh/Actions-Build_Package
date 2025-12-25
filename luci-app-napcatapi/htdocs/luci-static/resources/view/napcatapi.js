'use strict';
'require form';
'require poll';
'require rpc';
'require uci';
'require view';
'require fs';

/**
 * 检测服务是否运行（通过PID文件+进程校验，避免假死）
 * @returns {Promise<boolean>} 服务是否真正运行
 */
async function getServiceStatus() {
    try {
        const pidStat = await L.resolveDefault(fs.stat('/var/run/napcatapi.pid'), null);
        if (!pidStat) return false;

        const pidContent = await fs.read('/var/run/napcatapi.pid');
        const pid = parseInt(pidContent.trim());
        if (isNaN(pid)) return false;

        const procExists = await L.resolveDefault(
            rpc.call('system', 'proc_exists', [pid]),
            false
        );
        return procExists;
    } catch (e) {
        console.error('检测服务状态失败:', e);
        return false;
    }
}

/**
 * 生成32位小写字母+数字的随机字符
 * @returns {string} 32位随机token
 */
function generateRandomToken() {
    const chars = '0123456789abcdefghijklmnopqrstuvwxyz';
    let token = '';
    for (let i = 0; i < 32; i++) {
        token += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return token;
}


/**
 * 渲染状态文本+按钮（带token参数）
 * @param {boolean} isRunning 服务是否运行
 * @param {string} port Web端口
 * @param {string} token 32位随机token
 * @returns {string} 渲染后的HTML
 */
function renderStatus(isRunning, port, token) {
    const spanTemp = '<span style="color:%s"><strong>%s: %s</strong></span>';
    let renderHTML;

    if (isRunning) {
        const buttonInterface = String.format(
            '&#160;<a class="btn cbi-button" href="http://%s:%s?token=%s" target="_blank" rel="noreferrer noopener">%s</a>',
            window.location.hostname, port, token, _('Open Web Interface')
        );
        const buttonLog = String.format(
            '&#160;<a class="btn cbi-button" href="http://%s:%s/log?token=%s" target="_blank" rel="noreferrer noopener">%s</a>',
            window.location.hostname, port, token, _('Open Web log')
        );
        const buttonNapcat = String.format(
            '&#160;<a class="btn cbi-button" href="http://%s:%s/napcat?token=%s" target="_blank" rel="noreferrer noopener">%s</a>',
            window.location.hostname, port, token, _('Open Web napcat')
        );
        renderHTML = spanTemp.format('green', _('NapCat API'), _('RUNNING')) + buttonInterface + buttonLog + buttonNapcat;
    } else {
        renderHTML = spanTemp.format('red', _('NapCat API'), _('NOT RUNNING'));
    }

    return renderHTML;
}

// 扩展luci view
return view.extend({
    pollHandle: null,

    load: async function () {
        try {
            // 加载UCI配置
            const conf = await uci.load('napcatapi');
            
            // 静默处理token（无任何表单关联）
            let token = uci.get(conf, 'config', 'token');
            if (!token || token.length !== 32) {
                token = generateRandomToken();
                // 直接写入UCI，不通过表单选项
                uci.set('napcatapi', 'config', 'token', token);
                await uci.save('napcatapi');
                await uci.commit('napcatapi');
                //console.log('Token自动生成:', token);
            } else {
                //console.log('Token加载完成:', token);
            }

            // 3. 加载PID状态
            const pidStat = await L.resolveDefault(fs.stat('/var/run/napcatapi.pid'), null);

            return {
                isRunning: !!pidStat,
                conf: conf,
                token: token
            };
        } catch (e) {
            //console.error('加载初始化数据失败:', e);
            return { isRunning: false, conf: {}, token: generateRandomToken() };
        }
    },

    render(data) {
        let m, s, o;
        const spanTemp = '<span style="color:%s"><strong>%s: %s</strong></span>';

        // 读取配置
        const webport = uci.get(data.conf, 'config', 'port') || '5663';
        const webtoken = data.token;

        // 创建表单 
        m = new form.Map('napcatapi', _('NapCat API'),
            _('NapCat Robot call the API configuration page.'));

        // 状态显示区域
        s = m.section(form.TypedSection);
        s.anonymous = true;
        s.render = function () {
            const statusElement = E('p', { id: 'service_status' }, _('Collecting data...'));

            const pollFunc = async () => {
                try {
                    const isRunning = await getServiceStatus();
                    statusElement.innerHTML = renderStatus(isRunning, webport, webtoken);
                } catch (e) {
                    statusElement.innerHTML = spanTemp.format(
                        'orange', 
                        _('NapCat API'), 
                        _('DETECT ERROR')
                    );
                    console.error('轮询更新状态失败:', e);
                }
            };

            pollFunc();
            this.pollHandle = poll.add(pollFunc, 5000);

            return E('div', { class: 'cbi-section', id: 'status_bar' }, [statusElement]);
        };

        // 配置项Section
        s = m.section(form.NamedSection, 'config', 'napcatapi', _('Basic Settings'));

        // 启用/禁用开关
        o = s.option(form.Flag, 'enabled', _('Enable'));
        o.default = o.disabled;
        o.rmempty = false;

        // 端口配置
        o = s.option(form.Value, 'port', _('Port'));
        o.datatype = 'port';
        o.default = '5663';
        o.rmempty = false;
        o.description = _('NapCat API Web service port');

        // 配置文件路径
        o = s.option(form.Value, 'path_config', _('Config File Path'));
        o.default = '/etc/napcatapi';
        o.rmempty = true;
        o.description = _('NapCat API configuration file storage path');

        // 解密密钥（密码框）
        o = s.option(form.Value, 'pwd_config', _('Decrypt KEY'));
        o.default = '123456';
        o.password = true;
        o.rmempty = true;
        o.description = _('Decryption key for configuration file');

        // 在线配置URL
        o = s.option(form.Value, 'online_config', _('Online Config URL'));
        o.default = 'http://';
        o.rmempty = true;
        o.datatype = 'or(url,empty)';
        o.description = _('URL for online configuration pull');

        // 渲染表单
        return m.render();
    },

    // 保存配置时，自动携带token（确保修改其他配置时token不丢失）
    save: function(section_id, formvalue) {
        // 保留原有token值
        const token = uci.get('napcatapi', 'config', 'token') || generateRandomToken();
        // 合并token到保存的数据中
        formvalue.token = token;
        // 调用原生保存方法
        return uci.save('napcatapi', formvalue);
    },

    unload: function () {
        if (this.pollHandle) {
            poll.remove(this.pollHandle);
            this.pollHandle = null;
            console.log('NapCat API 轮询已停止');
        }
    }
});