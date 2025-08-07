# Security Policy

## Supported Versions

Use this section to tell people about which versions of your project are currently being supported with security updates.

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability within this project, please send an email to [your-email@example.com]. All security vulnerabilities will be promptly addressed.

Please include the following information in your report:

- Type of issue (buffer overflow, SQL injection, cross-site scripting, etc.)
- Full paths of source file(s) related to the vulnerability
- The location of the affected source code (tag/branch/commit or direct URL)
- Any special configuration required to reproduce the issue
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit it

This information will help us triage your report more quickly.

## Security Best Practices

When using this project, please follow these security best practices:

1. **Keep dependencies updated**: Regularly update all dependencies to their latest secure versions
2. **Use HTTPS**: Always use HTTPS in production environments
3. **Secure environment variables**: Never commit sensitive information like passwords or API keys
4. **Regular security audits**: Run security scans on your deployment regularly
5. **Monitor logs**: Keep an eye on application logs for suspicious activity

## Security Features

This project includes several security features:

- **Non-root Docker containers**: All containers run as non-root users
- **Security scanning**: Automated vulnerability scanning with Trivy and CodeQL
- **Rate limiting**: Built-in rate limiting to prevent abuse
- **Input validation**: Comprehensive input validation and sanitization
- **Secure headers**: Security headers configured in Nginx
