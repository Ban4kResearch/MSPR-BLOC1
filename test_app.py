import unittest
from unittest.mock import patch, MagicMock
from app import collecter_informations_locales, scanner_reseau, read_github_readme, tableau_de_bord

class TestApp(unittest.TestCase):

    @patch('subprocess.getoutput', return_value='192.168.1.1')
    @patch('platform.node', return_value='test-host')
    def test_collecter_informations_locales(self, mock_node, mock_getoutput):
        local_ip, hostname = collecter_informations_locales()
        self.assertEqual(local_ip, '192.168.1.1')
        self.assertEqual(hostname, 'test-host')

    @patch('nmap.PortScanner')
    @patch('subprocess.getoutput', return_value='ping-result')
    @patch('requests.get', return_value=MagicMock(status_code=200, text='test-version'))
    def test_scanner_reseau_and_read_github_readme(self, mock_get, mock_subprocess, mock_nmap):
        scanner_result = scanner_reseau()
        self.assertIn('hosts', scanner_result)
        self.assertIn('scan_result', scanner_result)
        self.assertIn('open_ports', scanner_result)

        version = read_github_readme('https://example.com')
        self.assertEqual(version, 'test-version')

    @patch('app.render_template')
    @patch('app.collecter_informations_locales', return_value=('192.168.1.1', 'test-host'))
    @patch('app.scanner_reseau', return_value={'hosts': ['192.168.1.1'], 'scan_result': 'test-scan', 'open_ports': []})
    @patch('subprocess.getoutput', return_value='ping-result')
    @patch('app.read_github_readme', return_value='test-version')
    def test_tableau_de_bord(self, mock_read_github_readme, mock_getoutput, mock_scanner_reseau, mock_collecter, mock_render_template):
        tableau_de_bord_result = tableau_de_bord()
        mock_render_template.assert_called_with(
            'dashboard.html', local_ip='192.168.1.1', hostname='test-host',
            machines_connectees=1, resultat_scan={'hosts': ['192.168.1.1'], 'scan_result': 'test-scan', 'open_ports': []},
            ping_result='ping-result', version='test-version'
        )

if __name__ == '__main__':
    unittest.main()
