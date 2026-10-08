"""Run with /usr/bin/python3; all settings remain in the memory backend."""
import importlib.util
import os
from pathlib import Path
import unittest

os.environ["GSETTINGS_BACKEND"] = "memory"
spec = importlib.util.spec_from_file_location("proxy", Path(__file__).parents[1] / "proxy-control.py")
proxy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(proxy)


class ProxyTests(unittest.TestCase):
    def setUp(self):
        self.root = proxy.settings()
        self.root.set_string("mode", "none")
        for name in self.root.list_children():
            child = self.root.get_child(name)
            child.set_string("host", "")
            child.set_int("port", 0)
        self.root.set_string("autoconfig-url", "")

    def save(self, kind="http", host="proxy.example.com", port="8080"):
        return proxy.apply(dict(action="save", kind=kind, host=host, port=port), self.root)

    def test_http_https_and_disable_preserve_address(self):
        result = self.save()
        self.assertTrue(result["enabled"])
        self.assertEqual(self.root.get_child("https").get_string("host"), "proxy.example.com")
        result = proxy.apply(dict(action="toggle", enabled=False), self.root)
        self.assertFalse(result["enabled"])
        self.assertEqual(result["host"], "proxy.example.com")
        self.assertTrue(proxy.apply(dict(action="toggle", enabled=True), self.root)["enabled"])

    def test_socks_ipv6_clears_old_http_routes(self):
        self.save()
        self.save(kind="socks", host="::1", port="1080")
        self.assertFalse(self.root.get_child("http").get_string("host"))
        self.assertFalse(self.root.get_child("https").get_string("host"))
        self.assertEqual(proxy.snapshot(self.root)["kind"], "socks")

    def test_invalid_input_does_not_change_settings(self):
        before = self.save()
        for host, port in [("https://proxy.example.com", "80"), ("a", "0"),
                           ("a", "65536"), ("a", "1.5"), ("a..b", "80"),
                           ("$(touch /tmp/bad)", "80")]:
            with self.subTest(host=host, port=port), self.assertRaises(ValueError):
                self.save(host=host, port=port)
            self.assertEqual(proxy.snapshot(self.root)["host"], before["host"])

    def test_cannot_enable_without_address(self):
        with self.assertRaises(ValueError):
            proxy.apply(dict(action="toggle", enabled=True), self.root)
        self.assertFalse(proxy.snapshot(self.root)["enabled"])


if __name__ == "__main__":
    unittest.main()
