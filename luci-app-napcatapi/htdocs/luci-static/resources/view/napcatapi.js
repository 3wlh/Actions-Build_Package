'use strict';
'require form';
'require poll';
'require rpc';
'require uci';
'require view';
'require fs';

function getServiceStatus() {
		let isRunning = false;
		return isRunning;
}

function renderStatus(isRunning, port) {
	var spanTemp = '<span style="color:%s"><strong>%s %s</strong></span>';
	let renderHTML;
	if (isRunning) {
		let button = String.format('&#160;<a class="btn cbi-button" href="http://%s:%s" target="_blank" rel="noreferrer noopener">%s</a>',
			window.location.hostname, port, _('Open Web Interface'));
		renderHTML = spanTemp.format('green', _('NapCat API'), _('RUNNING')) + button;
	} else {
		renderHTML = spanTemp.format('red', _('NapCat API'), _('NOT RUNNING'));
	}

	return renderHTML;
}

return view.extend({
	load: async function () {
		const promises = await Promise.all([
			L.resolveDefault(fs.stat('/var/run/napcat-api.pid'), null),
			uci.load('napcat-api')
		]);
	const data = {
			isRunning: promises[0],
			conf: promises[1]
		};
	return data;
	},
	render(data) {
		let m, s, o;
		let webport = (uci.get(data, 'config', 'port') || '5663');

		m = new form.Map('napcat-api', _('NapCat-API'),
			_('NapCat Robot call the API..'));

		s = m.section(form.TypedSection);
		s.anonymous = true;
		s.render = function () {
			poll.add(function () {
				return Promise.resolve().then(function() {
					let view = document.getElementById('service_status');
					view.innerHTML = renderStatus(data.isRunning, webport);
        });
			});

			return E('div', { class: 'cbi-section', id: 'status_bar' }, [
					E('p', { id: 'service_status' }, _('Collecting data...'))
			]);
		}

		s = m.section(form.NamedSection, 'config', 'napcat-api');

		o = s.option(form.Flag, 'enabled', _('Enable'));
		o.default = o.disabled;
		o.rmempty = false;

		o = s.option(form.Value, 'port', _('Port'));
		o.datatype = 'port';
		o.default = '5663';
		o.rmempty = false;

		o = s.option(form.Value, 'path_config', _('Config File Path'));
		o.default = '/etc/napcat-api/config.yaml';
		o.rmempty = true;
		
		o = s.option(form.Value, 'pwd_config', _('Decrypt KEY'));
		o.default = '123456';
		o.password = true;
		o.rmempty = true;
		
		o = s.option(form.Value, 'online_config', _('Online Config URL'));
		o.default = '';
		o.rmempty = true;
		o.datatype = 'or(url,empty)';

		return m.render();
	}
});