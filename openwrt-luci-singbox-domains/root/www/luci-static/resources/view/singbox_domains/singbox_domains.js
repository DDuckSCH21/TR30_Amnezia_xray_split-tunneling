'use strict';
'require view';

/* LuCI (luci-light) JS view: loads the CGI editor in an iframe. */

return view.extend({
	render: function () {
		return E('iframe', {
			src: '/cgi-bin/singbox-domains',
			style: 'width:100%; min-height:85vh; border:0; display:block; background:#fff'
		});
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
