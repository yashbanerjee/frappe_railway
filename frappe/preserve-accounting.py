"""Verify an isolated restore and preserve existing accounting navigation."""
import json
import os
import sys
from pathlib import Path

import frappe

site, mode = sys.argv[1:]
source_site = os.environ.get("SITE_NAME", "frontend")
state = json.loads(Path(source_site, "private", "upgrade-rollback-state.json").read_text())
frappe.init(site=site)
frappe.connect()
frappe.set_user("Administrator")
try:
    assert "erpnext" in frappe.get_installed_apps(), "ERPNext missing"
    if mode == "check":
        for doctype, count in state["counts"].items():
            assert frappe.db.count(doctype) == count, f"Record count changed: {doctype}"
    meta = frappe.get_meta("Wafeq E-Invoicing Settings")
    assert meta.custom and meta.issingle, "Custom Wafeq settings missing"
    for field in ("sandbox_api_key", "live_api_key", "webhook_signing_secret"):
        assert meta.get_field(field).fieldtype == "Password", "Credential field changed"
    marker = Path(site, "private", ".v1660-customizations-restored")
    if mode == "restore" and not marker.exists():
        for icon in state["icons"]:
            if frappe.db.exists("Desktop Icon", icon["name"]):
                frappe.db.set_value("Desktop Icon", icon["name"], "hidden", icon["hidden"])
        for workspace in state["workspaces"]:
            if frappe.db.exists("Workspace", workspace["name"]):
                frappe.db.set_value("Workspace", workspace["name"], "is_hidden", workspace["is_hidden"])
        sidebar = frappe.get_doc("Workspace Sidebar", "Invoicing")
        settings_type = "Wafeq E-Invoicing Settings"
        if not any(item.link_to == settings_type for item in sidebar.items):
            sidebar.append("items", {"label": "Wafeq E-Invoicing", "type": "Link", "link_type": "DocType", "link_to": settings_type, "icon": "integration"})
            sidebar.save()
        for user in state["profiles"]:
            frappe.db.set_value("User", user["name"], {"module_profile": user["module_profile"], "default_workspace": user["default_workspace"]})
        frappe.db.commit()
        frappe.clear_cache()
        marker.touch()
    print("Accounting records, ERPNext installation and encrypted Wafeq fields verified")
finally:
    frappe.destroy()
