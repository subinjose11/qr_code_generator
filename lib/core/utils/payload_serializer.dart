import '../../data/models/qr_type.dart';

class PayloadSerializer {
  static String serialize(QrType type, Map<String, String> fields) {
    switch (type) {
      case QrType.url:
        final url = fields['url']?.trim() ?? '';
        if (url.startsWith('http://') || url.startsWith('https://')) {
          return url;
        }
        return 'https://$url';

      case QrType.multiUrl:
        final title = fields['title']?.trim() ?? 'Links';
        final links = fields['links']?.trim() ?? '';
        return '$title\n\n$links';

      case QrType.vCard:
        final firstName = fields['firstName']?.trim() ?? '';
        final lastName = fields['lastName']?.trim() ?? '';
        final fullName = '$firstName $lastName'.trim();
        final org = fields['organization']?.trim() ?? '';
        final title = fields['jobTitle']?.trim() ?? '';
        final phone = fields['phone']?.trim() ?? '';
        final email = fields['email']?.trim() ?? '';
        final address = fields['address']?.trim() ?? '';
        final website = fields['website']?.trim() ?? '';
        final note = fields['note']?.trim() ?? '';

        final buffer = StringBuffer();
        buffer.writeln('BEGIN:VCARD');
        buffer.writeln('VERSION:3.0');
        buffer.writeln('N:$lastName;$firstName;;;');
        buffer.writeln('FN:$fullName');
        if (org.isNotEmpty) buffer.writeln('ORG:$org');
        if (title.isNotEmpty) buffer.writeln('TITLE:$title');
        if (phone.isNotEmpty) buffer.writeln('TEL;TYPE=WORK,VOICE:$phone');
        if (email.isNotEmpty) buffer.writeln('EMAIL;TYPE=PREF,INTERNET:$email');
        if (website.isNotEmpty) buffer.writeln('URL:$website');
        if (address.isNotEmpty) buffer.writeln('ADR;TYPE=WORK:;;$address;;;;');
        if (note.isNotEmpty) buffer.writeln('NOTE:$note');
        buffer.write('END:VCARD');
        return buffer.toString();

      case QrType.email:
        final to = fields['email']?.trim() ?? '';
        final subject = Uri.encodeComponent(fields['subject']?.trim() ?? '');
        final body = Uri.encodeComponent(fields['body']?.trim() ?? '');
        var query = '';
        if (subject.isNotEmpty && body.isNotEmpty) {
          query = '?subject=$subject&body=$body';
        } else if (subject.isNotEmpty) {
          query = '?subject=$subject';
        } else if (body.isNotEmpty) {
          query = '?body=$body';
        }
        return 'mailto:$to$query';

      case QrType.phone:
        final phone = fields['phone']?.trim().replaceAll(RegExp(r'[\s\-]'), '') ?? '';
        return 'tel:$phone';

      case QrType.sms:
        final phone = fields['phone']?.trim().replaceAll(RegExp(r'[\s\-]'), '') ?? '';
        final message = Uri.encodeComponent(fields['message']?.trim() ?? '');
        return 'sms:$phone?body=$message';

      case QrType.whatsapp:
        var phone = fields['phone']?.trim().replaceAll(RegExp(r'[^\d]'), '') ?? '';
        final text = Uri.encodeComponent(fields['message']?.trim() ?? '');
        if (text.isNotEmpty) {
          return 'https://wa.me/$phone?text=$text';
        }
        return 'https://wa.me/$phone';

      case QrType.telegram:
        final username = fields['username']?.trim().replaceAll('@', '') ?? '';
        return 'https://t.me/$username';

      case QrType.instagram:
        final handle = fields['username']?.trim().replaceAll('@', '') ?? '';
        return 'https://instagram.com/$handle';

      case QrType.facebook:
        final profile = fields['profile']?.trim() ?? '';
        if (profile.startsWith('http://') || profile.startsWith('https://')) {
          return profile;
        }
        return 'https://facebook.com/$profile';

      case QrType.twitter:
        final handle = fields['username']?.trim().replaceAll('@', '') ?? '';
        return 'https://x.com/$handle';

      case QrType.youtube:
        final link = fields['url']?.trim() ?? '';
        if (link.startsWith('http://') || link.startsWith('https://')) {
          return link;
        }
        return 'https://youtube.com/$link';

      case QrType.linkedin:
        final link = fields['profile']?.trim() ?? '';
        if (link.startsWith('http://') || link.startsWith('https://')) {
          return link;
        }
        return 'https://linkedin.com/in/$link';

      case QrType.tiktok:
        final handle = fields['username']?.trim().replaceAll('@', '') ?? '';
        return 'https://tiktok.com/@$handle';

      case QrType.spotify:
        final link = fields['url']?.trim() ?? '';
        return link;

      case QrType.wifi:
        final ssid = fields['ssid']?.trim() ?? '';
        final password = fields['password']?.trim() ?? '';
        final type = fields['encryption']?.trim() ?? 'WPA';
        final isHidden = fields['hidden'] == 'true';
        return 'WIFI:S:$ssid;T:$type;P:$password;H:$isHidden;;';

      case QrType.map:
        final lat = fields['latitude']?.trim() ?? '0.0';
        final lng = fields['longitude']?.trim() ?? '0.0';
        return 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

      case QrType.text:
        return fields['text']?.trim() ?? '';

      case QrType.upi:
        var pa = fields['vpa']?.trim() ?? '';
        if (pa.startsWith('upi://pay?')) {
          return pa;
        }
        if (pa.contains('pa=')) {
          final match = RegExp(r'pa=([a-zA-Z0-9.\-_@]+)').firstMatch(pa);
          if (match != null) pa = match.group(1) ?? pa;
        }
        pa = pa.replaceAll(' ', '');

        var name = fields['name']?.trim() ?? '';
        if (name.isEmpty) {
          name = pa.contains('@') ? pa.split('@').first : (pa.isNotEmpty ? pa : 'Merchant');
        }
        final pn = Uri.encodeComponent(name);

        final amRaw = fields['amount']?.trim() ?? '';
        String amParam = '';
        if (amRaw.isNotEmpty) {
          final cleaned = amRaw.replaceAll(RegExp(r'[^0-9.]'), '');
          if (cleaned.isNotEmpty) {
            final parsed = double.tryParse(cleaned);
            if (parsed != null && parsed > 0) {
              amParam = '&am=${parsed.toStringAsFixed(2)}';
            }
          }
        }

        final note = fields['note']?.trim() ?? '';
        final tnParam = note.isNotEmpty ? '&tn=${Uri.encodeComponent(note)}' : '';

        // NPCI UPI specification requires unencoded @ in 'pa' for PSP routing
        if (pa.isEmpty) {
          return 'upi://pay?pa=merchant@upi&pn=$pn$amParam&cu=INR$tnParam';
        }
        return 'upi://pay?pa=$pa&pn=$pn$amParam&cu=INR$tnParam';

      case QrType.calendar:
        final title = fields['title']?.trim() ?? 'Event';
        final location = fields['location']?.trim() ?? '';
        final desc = fields['description']?.trim() ?? '';
        final start = fields['startDate']?.trim() ?? '';
        final end = fields['endDate']?.trim() ?? '';

        final buffer = StringBuffer();
        buffer.writeln('BEGIN:VCALENDAR');
        buffer.writeln('VERSION:2.0');
        buffer.writeln('BEGIN:VEVENT');
        buffer.writeln('SUMMARY:$title');
        if (location.isNotEmpty) buffer.writeln('LOCATION:$location');
        if (desc.isNotEmpty) buffer.writeln('DESCRIPTION:$desc');
        if (start.isNotEmpty) buffer.writeln('DTSTART:$start');
        if (end.isNotEmpty) buffer.writeln('DTEND:$end');
        buffer.writeln('END:VEVENT');
        buffer.write('END:VCALENDAR');
        return buffer.toString();
    }
  }
}
