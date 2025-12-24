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
        // 1. 检查PID文件是否存在
        const pidStat = await L.resolveDefault(fs.stat('/var/run/napcatapi.pid'), null);
        if (!pidStat) return false;

        // 2. 读取PID并校验进程是否存活（避免PID文件残留导致误判）
        const pidContent = await fs.read('/var/run/napcatapi.pid');
        const pid = parseInt(pidContent.trim());
        if (isNaN(pid)) return false;

        // 3. 通过rpc调用检测进程是否存在（OpenWrt luci 标准方式）
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
 * 渲染状态文本+按钮
 * @param {boolean} isRunning 服务是否运行
 * @param {string} port Web端口
 * @returns {string} 渲染后的HTML
 */
function renderStatus(isRunning, port) {
    const spanTemp = '<span style="color:%s"><strong>%s: %s</strong></span>';
    let renderHTML;

    if (isRunning) {
        // 拼接两个按钮（Web界面 + 日志）
        const buttonInterface = String.format(
            '&#160;<a class="btn cbi-button" href="http://%s:%s" target="_blank" rel="noreferrer noopener">%s</a>',
            window.location.hostname, port, _('Open Web Interface')
        );
        const buttonLog = String.format(
            '&#160;<a class="btn cbi-button" href="http://%s:%s/log" target="_blank" rel="noreferrer noopener">%s</a>',
            window.location.hostname, port, _('Open Web log')
        );
        const buttonNapcat = String.format(
            '&#160;<a class="btn cbi-button" href="http://%s:%s/napcat" target="_blank" rel="noreferrer noopener">%s</a>',
            window.location.hostname, port, _('Open Web napcat')
        );
        renderHTML = spanTemp.format('green', _('NapCat API'), _('RUNNING')) + buttonInterface + buttonLog + buttonNapcat;
    } else {
        renderHTML = spanTemp.format('red', _('NapCat API'), _('NOT RUNNING'));
    }

    return renderHTML;
}

// 扩展luci view
return view.extend({
    // 保存轮询句柄，用于页面销毁时停止轮询
    pollHandle: null,
    /*加载初始化数据（PID文件 + UCI配置）*/
    load: async function () {
        try {
            // 并行加载PID状态和UCI配置
            const [pidStat, conf] = await Promise.all([
                L.resolveDefault(fs.stat('/var/run/napcatapi.pid'), null),
                uci.load('napcatapi')
            ]);

            // 初始状态：PID文件存在则标记为运行中（后续轮询会实时校验）
            return {
                isRunning: !!pidStat,
                conf: conf
            };
        } catch (e) {
            console.error('加载初始化数据失败:', e);
            return { isRunning: false, conf: {} };
        }
    },

    /**
     * 渲染页面
     * @param {object} data load方法返回的初始化数据
     * @returns {HTMLElement} 渲染后的页面DOM
     */
    render(data) {
        let m, s, o;
        const spanTemp = '<span style="color:%s"><strong>%s: %s</strong></span>'; // 修复变量作用域问题

        // 正确从UCI配置中读取端口
        const webport = uci.get(data.conf, 'config', 'port') || '5663';

        // 创建配置表单
        m = new form.Map('napcatapi', _('NapCat API'),
            _('NapCat Robot call the API configuration page.'));

        // 状态显示区域（自定义Section）
        s = m.section(form.TypedSection);
        s.anonymous = true;
        s.render = function () {
            // 初始化状态显示
            const statusElement = E('p', { id: 'service_status' }, _('Collecting data...'));

            // 定义轮询执行函数
            const pollFunc = async () => {
                try {
                    // 实时检测服务状态
                    const isRunning = await getServiceStatus();
                    // 更新状态显示
                    statusElement.innerHTML = renderStatus(isRunning, webport);
                } catch (e) {
                    // 异常状态渲染（修复spanTemp作用域）
                    statusElement.innerHTML = spanTemp.format(
                        'orange', 
                        _('NapCat API'), 
                        _('DETECT ERROR')
                    );
                    console.error('轮询更新状态失败:', e);
                }
            };

            // 立即执行一次轮询（避免初始加载延迟）
            pollFunc();

            // 配置周期性轮询（每5秒更新，保存句柄）
            this.pollHandle = poll.add(pollFunc, 5000);

            // 返回状态栏DOM
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
        o.datatype = 'port'; // 自动校验端口范围(1-65535)
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
        o.password = true; // 隐藏输入内容
        o.rmempty = true;
        o.description = _('Decryption key for configuration file');

        // 在线配置URL
        o = s.option(form.Value, 'online_config', _('Online Config URL'));
        o.default = 'http://';
        o.rmempty = true;
        o.datatype = 'or(url,empty)'; // 校验URL格式或为空
        o.description = _('URL for online configuration pull');

        // 渲染完整表单
        return m.render();
    },

    //页面销毁时停止轮询（关键：避免内存泄漏）
    unload: function () {
        if (this.pollHandle) {
            poll.remove(this.pollHandle);
            this.pollHandle = null;
            console.log('NapCat API 轮询已停止');
        }
    }
});