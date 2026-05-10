module("luci.controller.singbox_domains", package.seeall)

function index()
	-- Under System: parent menu exists on all full LuCI images.
	local e = entry({"admin", "system", "singbox_domains"}, call("action_index"), _("Sing-box domains"), 43)
	e.leaf = true
end

function action_index()
	local http = require "luci.http"
	local disp = require "luci.dispatcher"
	local fs = require "nixio.fs"
	local sys = require "luci.sys"

	local listfile = "/etc/sing-box/domains.list"

	if http.formvalue("apply") == "1" then
		local text = http.formvalue("domains") or ""
		text = text:gsub("\r\n", "\n")
		fs.mkdirr("/etc/sing-box")
		fs.writefile(listfile, text)
		sys.call("/usr/bin/singbox-apply-domains >/tmp/singbox-apply-domains.log 2>&1")
		http.redirect(disp.build_url("admin/system/singbox_domains"))
		return
	end

	luci.template.render("singbox_domains", {
		action_url = disp.build_url("admin/system/singbox_domains"),
		domains = fs.readfile(listfile) or "",
		log = fs.readfile("/tmp/singbox-apply-domains.log") or "",
	})
end
