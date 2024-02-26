import unittest
from unittest.mock import patch
import sys 
sys.path.append('./')  # Assuming 'scripts.py' is in the same directory as the test script

from script import collecter_informations_locales, scanner_reseau, read_github_readme, check_and_update_repository

class TestScripts(unittest.TestCase):

    @patch('subprocess.getoutput', return_value='192.168.1.1')
    @patch('platform.node', return_value='test_hostname')
    def test_collecter_informations_locales(self, mock_node, mock_getoutput):
        local_ip, hostname = collecter_informations_locales()
        self.assertEqual(local_ip, '192.168.1.1')
        self.assertEqual(hostname, 'test_hostname')

    @patch('nmap.PortScanner')
    @patch('json.dump')
    def test_scanner_reseau(self, mock_json_dump, mock_portscanner):
        mock_portscanner_instance = mock_portscanner.return_value
        mock_portscanner_instance.all_hosts.return_value = ['192.168.1.1']
        mock_portscanner_instance.csv.return_value = 'scan_result_csv'

        result = scanner_reseau()
        self.assertEqual(result['hosts'], ['192.168.1.1'])
        self.assertEqual(result['scan_result'], 'scan_result_csv')

    @patch('requests.get')
    def test_read_github_readme(self, mock_requests_get):
        mock_response = mock_requests_get.return_value
        mock_response.status_code = 200
        mock_response.text = 'Test version content'

        version = read_github_readme('https://example.com')
        self.assertEqual(version, 'Test version content')

    @patch('subprocess.run')
    @patch('os.path.exists', return_value=False)
    @patch('os.chdir')
    def test_check_and_update_repository(self, mock_chdir, mock_exists, mock_run):
        check_and_update_repository()
        mock_run.assert_called_with(['git', 'clone', 'https://github.com/NChansard/MSPR-BLOC1.git', '/root/hakan/MSPR-BLOC1'])

if __name__ == '__main__':
    unittest.main()