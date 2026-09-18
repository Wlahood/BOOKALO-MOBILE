import 'workflow_form_screen.dart';

const _region = FormFieldSpec(
  'region',
  'Regione',
  kind: InputKind.lookup,
  source: '/locations/regions',
  required: true,
);
const _location = FormFieldSpec(
  'location_id',
  'Provincia',
  kind: InputKind.lookup,
  source: '/locations/provinces?region={region}',
  required: true,
);
const _title = FormFieldSpec('title', 'Titolo');
const _message = FormFieldSpec(
  'message',
  'Messaggio',
  kind: InputKind.multiline,
);
const _mode = FormFieldSpec(
  'mode',
  'Disponibilità',
  kind: InputKind.choice,
  choices: {'single_day': 'Un giorno', 'range': 'Intervallo di date'},
  initial: 'single_day',
  required: true,
);
const _start = FormFieldSpec(
  'start_date',
  'Data iniziale',
  kind: InputKind.date,
  required: true,
);
const _end = FormFieldSpec('end_date', 'Data finale', kind: InputKind.date);

List<FormFieldSpec> entityFields(String type, {bool admin = false}) => [
  const FormFieldSpec('name', 'Nome', required: true),
  _region,
  _location,
  const FormFieldSpec('description', 'Descrizione', kind: InputKind.multiline),
  const FormFieldSpec('email', 'Email', kind: InputKind.email),
  for (final key in ['website', 'instagram', 'facebook', if (!admin) 'youtube'])
    FormFieldSpec(
      '${key}_url',
      {
        'website': 'Sito web',
        'instagram': 'Instagram',
        'facebook': 'Facebook',
        'youtube': 'YouTube',
      }[key]!,
    ),
  if (type == 'bands') ...[
    const FormFieldSpec(
      'genres',
      'Generi musicali',
      kind: InputKind.lookup,
      source: '/genres',
      multiple: true,
    ),
    const FormFieldSpec('logo', 'Logo (massimo 2 MB)', kind: InputKind.file),
    if (!admin)
      for (final key in [
        'spotify',
        'youtube_music',
        'deezer',
        'amazon_music',
        'soundcloud',
        'bandcamp',
      ])
        FormFieldSpec('${key}_url', key.replaceAll('_', ' ')),
  ] else ...[
    const FormFieldSpec('capacity', 'Capienza', kind: InputKind.number),
    const FormFieldSpec('street', 'Via'),
    const FormFieldSpec('street_number', 'Numero civico'),
    const FormFieldSpec('postal_code', 'CAP'),
    const FormFieldSpec('city', 'Città'),
    const FormFieldSpec(
      'profile_image',
      'Immagine profilo',
      kind: InputKind.file,
    ),
  ],
  if (admin && type == 'bands')
    const FormFieldSpec(
      'is_suspended',
      'Profilo sospeso',
      kind: InputKind.toggle,
      initial: false,
    ),
];
List<FormFieldSpec> campaignFields(String type) => [
  _title,
  _message,
  _mode,
  _start,
  _end,
  FormFieldSpec(
    type == 'bands' ? 'venue_ids' : 'band_ids',
    type == 'bands' ? 'Locali destinatari' : 'Band destinatarie',
    kind: InputKind.lookup,
    source:
        '/workspace/my/campaigns/search/${type == 'bands' ? 'venues' : 'bands'}',
    multiple: true,
    required: true,
  ),
];
List<FormFieldSpec> boardFields(String type) => [
  _title,
  _message,
  _mode,
  _start,
  _end,
  if (type == 'bands') ...[
    const FormFieldSpec(
      'region',
      'Regione',
      kind: InputKind.lookup,
      source: '/locations/regions',
    ),
    const FormFieldSpec('province_code', 'Sigla provincia'),
  ],
];
const bookingFields = [
  FormFieldSpec(
    'venue_id',
    'Locale',
    kind: InputKind.lookup,
    source: '/workspace/my/campaigns/search/venues',
    required: true,
  ),
  _start,
  _end,
  FormFieldSpec('start_time', 'Ora iniziale', kind: InputKind.time),
  FormFieldSpec('end_time', 'Ora finale', kind: InputKind.time),
  _message,
];
const claimFields = [
  FormFieldSpec(
    'method',
    'Metodo di verifica',
    kind: InputKind.choice,
    choices: {
      'manual': 'Verifica manuale',
      'instagram': 'Instagram',
      'facebook': 'Facebook',
      'email': 'Email',
    },
    initial: 'manual',
  ),
  FormFieldSpec(
    'email_to_verify',
    'Email da verificare',
    kind: InputKind.email,
  ),
  _message,
];
const eventFields = [
  FormFieldSpec('title', 'Titolo', required: true),
  FormFieldSpec(
    'start_datetime',
    'Inizio',
    kind: InputKind.datetime,
    required: true,
  ),
  FormFieldSpec('end_datetime', 'Fine', kind: InputKind.datetime),
  FormFieldSpec('description', 'Descrizione', kind: InputKind.multiline),
  FormFieldSpec(
    'band_ids',
    'Band (ordine di esibizione)',
    kind: InputKind.lookup,
    source: '/workspace/my/campaigns/search/bands',
    multiple: true,
  ),
  FormFieldSpec('poster_image', 'Locandina', kind: InputKind.file),
  FormFieldSpec('facebook_url', 'Facebook'),
  FormFieldSpec('instagram_url', 'Instagram'),
  FormFieldSpec(
    'has_custom_location',
    'Usa luogo diverso dal locale',
    kind: InputKind.toggle,
    initial: false,
  ),
  FormFieldSpec('custom_location_name', 'Nome luogo'),
  FormFieldSpec('custom_location_address', 'Indirizzo luogo'),
  FormFieldSpec('custom_location_city', 'Città luogo'),
  FormFieldSpec('custom_location_province_code', 'Sigla provincia luogo'),
  FormFieldSpec('custom_location_region', 'Regione luogo'),
];
const profileFields = [
  FormFieldSpec('name', 'Nome', required: true),
  FormFieldSpec('email', 'Email', kind: InputKind.email, required: true),
  FormFieldSpec('phone', 'Telefono'),
  FormFieldSpec('city', 'Città'),
  FormFieldSpec('avatar', 'Avatar', kind: InputKind.file),
];
const passwordFields = [
  FormFieldSpec(
    'current_password',
    'Password attuale',
    kind: InputKind.password,
    required: true,
  ),
  FormFieldSpec(
    'password',
    'Nuova password',
    kind: InputKind.password,
    required: true,
  ),
  FormFieldSpec(
    'password_confirmation',
    'Conferma nuova password',
    kind: InputKind.password,
    required: true,
  ),
];
