# Backstage


# Backpass: Backstage Exploit Automation Tool

**Backpass** is a tool designed to automate testing for vulnerabilities in [Backstage](https://backstage.io) instances. It focuses on assessing instances for the lack of authentication vulnerability and three other identified attack scenarios.

This repository includes:
- **Automation scripts** for detecting Backstage vulnerabilities.
- **Custom wordlists** for fuzzing Backstage endpoints effectively.

## Backpass Features
1. **Authentication bypass detection**: Tests for instances that lack proper authentication controls.
2. **API abuse scenarios**: Exploits common misconfigurations in API endpoints.
3. **Plugin vulnerability checks**: Identifies exploitable plugins installed in the Backstage instance.
4. **Fuzzing-ready payloads**: Includes wordlists curated for Backstage-specific directories, endpoints, and parameters.

## Usage

1. Copy this repository
2. `chmod +x backpass.sh`
3. `./backpass.sh [-u url] [-l url_list_file]`

   
**Note**: This tool is for authorized testing and research/educational purposes only.

