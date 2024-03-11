import unittest
from unittest.mock import patch, call, ANY
import sys
sys.path.append('./')

from script import collecter_informations_locales, scanner_reseau, read_github_readme, check_and_update_repository

class TestScripts(unittest.TestCase):

    @patch('subprocess.getoutput', return_value='192.168.1.1')
    @patch('platform.node', return_value='test_hostname')
    def test_collecter_informations_locales(self, mock_node, mock_getoutput):
        local_ip, hostname = collecter_informations_locales()
        self.assertEqual(local_ip, '192.168.1.1')
        self.assertEqual(hostname, 'test_hostname')

    @patch('subprocess.getoutput', return_value='192.168.1.1')
    @patch('platform.node', return_value='test_hostname')
    @patch('nmap.PortScanner')
    @patch('json.dump')
    def test_scanner_reseau(self, mock_json_dump, mock_portscanner, mock_node, mock_getoutput):
        mock_portscanner_instance = mock_portscanner.return_value
        mock_portscanner_instance.all_hosts.return_value = ['192.168.1.1']
        mock_portscanner_instance.csv.return_value = 'local_ip_csv'

        result = scanner_reseau()
        local_ip = mock_getoutput.return_value  # Get the local IP dynamically
        self.assertEqual(result['hosts'], ['192.168.1.1'])
        self.assertIn(local_ip, result)  # Check if the local IP is present in the result keys
        self.assertEqual(result[local_ip], 'local_ip_csv')  # Use the correct key

    @patch('requests.get')
    def test_read_github_readme(self, mock_requests_get):
        mock_response = mock_requests_get.return_value
        mock_response.status_code = 200
        mock_response.text = 'Test version content'

        version = read_github_readme('https://github.com/NChansard/MSPR-BLOC1/blob/main/version.md')
        self.assertEqual(version, 'Test version content')

    @patch('subprocess.run')
    @patch('os.path.exists')
    @patch('os.chdir')
    def test_check_and_update_repository(self, mock_chdir, mock_exists, mock_run):
        mock_exists.side_effect = [False, True]  # Simule un dépôt inexistant, puis existant
        check_and_update_repository()
        expected_calls = [
            call(['git', 'clone', 'https://github.com/NChansard/MSPR-BLOC1.git', ANY], check=True),
            call(['git', 'pull'], check=True)
        ]
        mock_run.assert_has_calls(expected_calls)

if __name__ == '__main__':
    unittest.main()
