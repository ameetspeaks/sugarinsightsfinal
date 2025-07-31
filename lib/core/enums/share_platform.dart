enum SharePlatform {
  whatsapp,
  email,
  systemShare;

  String get value {
    switch (this) {
      case SharePlatform.whatsapp:
        return 'whatsapp';
      case SharePlatform.email:
        return 'email';
      case SharePlatform.systemShare:
        return 'system_share';
    }
  }
}