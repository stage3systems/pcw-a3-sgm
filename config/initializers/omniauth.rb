Rails.application.config.middleware.use OmniAuth::Builder do
  provider :saml,
    :assertion_consumer_service_url => "http://localhost:3000/users/auth/saml/callback",
    :issuer                         => "https://monson-disbursments.evax.fr",
    :idp_sso_target_url             => "https://localhost:8001/saml/authn",
    :idp_cert                       => "-----BEGIN CERTIFICATE-----\nMIIC6DCCAdCgAwIBAgIJAKoWbNUAva2/MA0GCSqGSIb3DQEBBQUAMBYxFDASBgNV\nBAMTC2V2YXgtbGFwdG9wMB4XDTEzMDIwNzEwMzczNFoXDTIzMDIwNTEwMzczNFow\nFjEUMBIGA1UEAxMLZXZheC1sYXB0b3AwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAw\nggEKAoIBAQCtzGsjLb2fuVQT4OQB41F7k4F2ZH+rO9xTkoZeZJdNxc+RumME3RBL\nTcqXdOBh033jtm9DgvO9wV0FtkQI373hkrgHIMZvuI0mHbTYO3D6Kk64QszdArg2\nHtUHWRyfIytrEvNiQIqJ7B8WmBtO4IAXxHJ1HdpS/e0+FEiUIAlPr1Yz71NGoGjm\nlTxySVysHjfSJmr4uU9xTNrMUeBA0alpfKk9X6R0gsLiKUL+3f9GhFG5tB5AtmNF\n9lsp1HWp3DgMTLvoIz1ZGLbfG/v13L0Rz/yEbUqR4K5luM/80cB1ax1xrcCz1RTB\nKe4uWot3Iat9TFgxJ4ONPNKHy+Ezd8cDAgMBAAGjOTA3MBYGA1UdEQQPMA2CC2V2\nYXgtbGFwdG9wMB0GA1UdDgQWBBRlr+WTOaQvVxhdwDVcg9kz8nb4RDANBgkqhkiG\n9w0BAQUFAAOCAQEAjF3/rZj+50Ns7kXRyvj+QKL0+DuuxOQ4vqAfv1QQBqeGYddD\nISvj3cEEVSXhEtqluXPFlZXjDaJy9GkeiS01ILihRlhDpTGPwA//GP+/W9ht2AtS\ngD95GlAMLvFLX0VyKEpwliCMWl1GQi3m1sFmOm58RUNA4JxHku5gznsAsZSkkM1M\n8oxnfPn3dCnn96FNwgHZKSHilDB0se5Q9tJs+D0Ab+CmRIT3fiv/ykaU6kws8r1h\nPlDGM6nbLb2Y9Ittq9OKP8eK2oWQS28HXLf9Ef6011qRZZ/RzQ+XZFL3tRklgUvV\noU3vIgMbetf1YZ0wmkuUztm0cHP5veBkmpKCkg==\n-----END CERTIFICATE-----",
    :idp_cert_fingerprint           => "7D:83:48:1B:09:0A:E1:BE:6A:2C:B3:D2:3E:FD:BF:85:C6:20:FE:AC",
    :name_identifier_format         => "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
end
