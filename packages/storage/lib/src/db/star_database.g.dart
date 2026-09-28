// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'star_database.dart';

// ignore_for_file: type=lint
class $SubscriptionsTable extends Subscriptions
    with TableInfo<$SubscriptionsTable, SubscriptionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubscriptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<int> fetchedAt = GeneratedColumn<int>(
    'fetched_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawMeta = const VerificationMeta('raw');
  @override
  late final GeneratedColumn<String> raw = GeneratedColumn<String>(
    'raw',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, kind, url, etag, fetchedAt, raw];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subscriptions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SubscriptionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    }
    if (data.containsKey('raw')) {
      context.handle(
        _rawMeta,
        raw.isAcceptableOrUnknown(data['raw']!, _rawMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SubscriptionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubscriptionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fetched_at'],
      ),
      raw: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw'],
      ),
    );
  }

  @override
  $SubscriptionsTable createAlias(String alias) {
    return $SubscriptionsTable(attachedDatabase, alias);
  }
}

class SubscriptionRow extends DataClass implements Insertable<SubscriptionRow> {
  final int id;
  final String kind;
  final String? url;
  final String? etag;
  final int? fetchedAt;
  final String? raw;
  const SubscriptionRow({
    required this.id,
    required this.kind,
    this.url,
    this.etag,
    this.fetchedAt,
    this.raw,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    if (!nullToAbsent || fetchedAt != null) {
      map['fetched_at'] = Variable<int>(fetchedAt);
    }
    if (!nullToAbsent || raw != null) {
      map['raw'] = Variable<String>(raw);
    }
    return map;
  }

  SubscriptionsCompanion toCompanion(bool nullToAbsent) {
    return SubscriptionsCompanion(
      id: Value(id),
      kind: Value(kind),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
      fetchedAt: fetchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(fetchedAt),
      raw: raw == null && nullToAbsent ? const Value.absent() : Value(raw),
    );
  }

  factory SubscriptionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubscriptionRow(
      id: serializer.fromJson<int>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      url: serializer.fromJson<String?>(json['url']),
      etag: serializer.fromJson<String?>(json['etag']),
      fetchedAt: serializer.fromJson<int?>(json['fetchedAt']),
      raw: serializer.fromJson<String?>(json['raw']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(kind),
      'url': serializer.toJson<String?>(url),
      'etag': serializer.toJson<String?>(etag),
      'fetchedAt': serializer.toJson<int?>(fetchedAt),
      'raw': serializer.toJson<String?>(raw),
    };
  }

  SubscriptionRow copyWith({
    int? id,
    String? kind,
    Value<String?> url = const Value.absent(),
    Value<String?> etag = const Value.absent(),
    Value<int?> fetchedAt = const Value.absent(),
    Value<String?> raw = const Value.absent(),
  }) => SubscriptionRow(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    url: url.present ? url.value : this.url,
    etag: etag.present ? etag.value : this.etag,
    fetchedAt: fetchedAt.present ? fetchedAt.value : this.fetchedAt,
    raw: raw.present ? raw.value : this.raw,
  );
  SubscriptionRow copyWithCompanion(SubscriptionsCompanion data) {
    return SubscriptionRow(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      url: data.url.present ? data.url.value : this.url,
      etag: data.etag.present ? data.etag.value : this.etag,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      raw: data.raw.present ? data.raw.value : this.raw,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubscriptionRow(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('url: $url, ')
          ..write('etag: $etag, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('raw: $raw')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, kind, url, etag, fetchedAt, raw);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubscriptionRow &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.url == this.url &&
          other.etag == this.etag &&
          other.fetchedAt == this.fetchedAt &&
          other.raw == this.raw);
}

class SubscriptionsCompanion extends UpdateCompanion<SubscriptionRow> {
  final Value<int> id;
  final Value<String> kind;
  final Value<String?> url;
  final Value<String?> etag;
  final Value<int?> fetchedAt;
  final Value<String?> raw;
  const SubscriptionsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.url = const Value.absent(),
    this.etag = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.raw = const Value.absent(),
  });
  SubscriptionsCompanion.insert({
    this.id = const Value.absent(),
    required String kind,
    this.url = const Value.absent(),
    this.etag = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.raw = const Value.absent(),
  }) : kind = Value(kind);
  static Insertable<SubscriptionRow> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<String>? url,
    Expression<String>? etag,
    Expression<int>? fetchedAt,
    Expression<String>? raw,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (url != null) 'url': url,
      if (etag != null) 'etag': etag,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (raw != null) 'raw': raw,
    });
  }

  SubscriptionsCompanion copyWith({
    Value<int>? id,
    Value<String>? kind,
    Value<String?>? url,
    Value<String?>? etag,
    Value<int?>? fetchedAt,
    Value<String?>? raw,
  }) {
    return SubscriptionsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      url: url ?? this.url,
      etag: etag ?? this.etag,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      raw: raw ?? this.raw,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<int>(fetchedAt.value);
    }
    if (raw.present) {
      map['raw'] = Variable<String>(raw.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubscriptionsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('url: $url, ')
          ..write('etag: $etag, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('raw: $raw')
          ..write(')'))
        .toString();
  }
}

class $SourceDefsTable extends SourceDefs
    with TableInfo<$SourceDefsTable, SourceDefRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SourceDefsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subIdMeta = const VerificationMeta('subId');
  @override
  late final GeneratedColumn<int> subId = GeneratedColumn<int>(
    'sub_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES subscriptions (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cmsVariantMeta = const VerificationMeta(
    'cmsVariant',
  );
  @override
  late final GeneratedColumn<String> cmsVariant = GeneratedColumn<String>(
    'cms_variant',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _endpointMeta = const VerificationMeta(
    'endpoint',
  );
  @override
  late final GeneratedColumn<String> endpoint = GeneratedColumn<String>(
    'endpoint',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _extRawMeta = const VerificationMeta('extRaw');
  @override
  late final GeneratedColumn<String> extRaw = GeneratedColumn<String>(
    'ext_raw',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _extUrlMeta = const VerificationMeta('extUrl');
  @override
  late final GeneratedColumn<String> extUrl = GeneratedColumn<String>(
    'ext_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceUrlMeta = const VerificationMeta(
    'sourceUrl',
  );
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
    'source_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jarRefMeta = const VerificationMeta('jarRef');
  @override
  late final GeneratedColumn<String> jarRef = GeneratedColumn<String>(
    'jar_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _capsSearchableMeta = const VerificationMeta(
    'capsSearchable',
  );
  @override
  late final GeneratedColumn<bool> capsSearchable = GeneratedColumn<bool>(
    'caps_searchable',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("caps_searchable" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _capsQuickSearchMeta = const VerificationMeta(
    'capsQuickSearch',
  );
  @override
  late final GeneratedColumn<bool> capsQuickSearch = GeneratedColumn<bool>(
    'caps_quick_search',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("caps_quick_search" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _capsFilterableMeta = const VerificationMeta(
    'capsFilterable',
  );
  @override
  late final GeneratedColumn<bool> capsFilterable = GeneratedColumn<bool>(
    'caps_filterable',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("caps_filterable" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _capsChangeableMeta = const VerificationMeta(
    'capsChangeable',
  );
  @override
  late final GeneratedColumn<bool> capsChangeable = GeneratedColumn<bool>(
    'caps_changeable',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("caps_changeable" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _headersMeta = const VerificationMeta(
    'headers',
  );
  @override
  late final GeneratedColumn<String> headers = GeneratedColumn<String>(
    'headers',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeoutSecMeta = const VerificationMeta(
    'timeoutSec',
  );
  @override
  late final GeneratedColumn<int> timeoutSec = GeneratedColumn<int>(
    'timeout_sec',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unsupportedReasonMeta = const VerificationMeta(
    'unsupportedReason',
  );
  @override
  late final GeneratedColumn<String> unsupportedReason =
      GeneratedColumn<String>(
        'unsupported_reason',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _sortMeta = const VerificationMeta('sort');
  @override
  late final GeneratedColumn<int> sort = GeneratedColumn<int>(
    'sort',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    key,
    subId,
    name,
    kind,
    cmsVariant,
    endpoint,
    extRaw,
    extUrl,
    sourceUrl,
    jarRef,
    capsSearchable,
    capsQuickSearch,
    capsFilterable,
    capsChangeable,
    headers,
    timeoutSec,
    unsupportedReason,
    enabled,
    sort,
    groupId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'source_defs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SourceDefRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('sub_id')) {
      context.handle(
        _subIdMeta,
        subId.isAcceptableOrUnknown(data['sub_id']!, _subIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('cms_variant')) {
      context.handle(
        _cmsVariantMeta,
        cmsVariant.isAcceptableOrUnknown(data['cms_variant']!, _cmsVariantMeta),
      );
    }
    if (data.containsKey('endpoint')) {
      context.handle(
        _endpointMeta,
        endpoint.isAcceptableOrUnknown(data['endpoint']!, _endpointMeta),
      );
    }
    if (data.containsKey('ext_raw')) {
      context.handle(
        _extRawMeta,
        extRaw.isAcceptableOrUnknown(data['ext_raw']!, _extRawMeta),
      );
    }
    if (data.containsKey('ext_url')) {
      context.handle(
        _extUrlMeta,
        extUrl.isAcceptableOrUnknown(data['ext_url']!, _extUrlMeta),
      );
    }
    if (data.containsKey('source_url')) {
      context.handle(
        _sourceUrlMeta,
        sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta),
      );
    }
    if (data.containsKey('jar_ref')) {
      context.handle(
        _jarRefMeta,
        jarRef.isAcceptableOrUnknown(data['jar_ref']!, _jarRefMeta),
      );
    }
    if (data.containsKey('caps_searchable')) {
      context.handle(
        _capsSearchableMeta,
        capsSearchable.isAcceptableOrUnknown(
          data['caps_searchable']!,
          _capsSearchableMeta,
        ),
      );
    }
    if (data.containsKey('caps_quick_search')) {
      context.handle(
        _capsQuickSearchMeta,
        capsQuickSearch.isAcceptableOrUnknown(
          data['caps_quick_search']!,
          _capsQuickSearchMeta,
        ),
      );
    }
    if (data.containsKey('caps_filterable')) {
      context.handle(
        _capsFilterableMeta,
        capsFilterable.isAcceptableOrUnknown(
          data['caps_filterable']!,
          _capsFilterableMeta,
        ),
      );
    }
    if (data.containsKey('caps_changeable')) {
      context.handle(
        _capsChangeableMeta,
        capsChangeable.isAcceptableOrUnknown(
          data['caps_changeable']!,
          _capsChangeableMeta,
        ),
      );
    }
    if (data.containsKey('headers')) {
      context.handle(
        _headersMeta,
        headers.isAcceptableOrUnknown(data['headers']!, _headersMeta),
      );
    }
    if (data.containsKey('timeout_sec')) {
      context.handle(
        _timeoutSecMeta,
        timeoutSec.isAcceptableOrUnknown(data['timeout_sec']!, _timeoutSecMeta),
      );
    }
    if (data.containsKey('unsupported_reason')) {
      context.handle(
        _unsupportedReasonMeta,
        unsupportedReason.isAcceptableOrUnknown(
          data['unsupported_reason']!,
          _unsupportedReasonMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('sort')) {
      context.handle(
        _sortMeta,
        sort.isAcceptableOrUnknown(data['sort']!, _sortMeta),
      );
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SourceDefRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SourceDefRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      subId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sub_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      cmsVariant: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cms_variant'],
      )!,
      endpoint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}endpoint'],
      ),
      extRaw: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ext_raw'],
      ),
      extUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ext_url'],
      ),
      sourceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_url'],
      ),
      jarRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}jar_ref'],
      ),
      capsSearchable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}caps_searchable'],
      )!,
      capsQuickSearch: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}caps_quick_search'],
      )!,
      capsFilterable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}caps_filterable'],
      )!,
      capsChangeable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}caps_changeable'],
      )!,
      headers: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}headers'],
      ),
      timeoutSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timeout_sec'],
      ),
      unsupportedReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unsupported_reason'],
      ),
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      sort: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      ),
    );
  }

  @override
  $SourceDefsTable createAlias(String alias) {
    return $SourceDefsTable(attachedDatabase, alias);
  }
}

class SourceDefRow extends DataClass implements Insertable<SourceDefRow> {
  final String key;
  final int? subId;
  final String name;
  final String kind;
  final String cmsVariant;
  final String? endpoint;
  final String? extRaw;
  final String? extUrl;
  final String? sourceUrl;

  /// 仅引用记录，永不执行（docs/05 §10）
  final String? jarRef;
  final bool capsSearchable;
  final bool capsQuickSearch;
  final bool capsFilterable;
  final bool capsChangeable;
  final String? headers;
  final int? timeoutSec;
  final String? unsupportedReason;
  final bool enabled;
  final int sort;
  final String? groupId;
  const SourceDefRow({
    required this.key,
    this.subId,
    required this.name,
    required this.kind,
    required this.cmsVariant,
    this.endpoint,
    this.extRaw,
    this.extUrl,
    this.sourceUrl,
    this.jarRef,
    required this.capsSearchable,
    required this.capsQuickSearch,
    required this.capsFilterable,
    required this.capsChangeable,
    this.headers,
    this.timeoutSec,
    this.unsupportedReason,
    required this.enabled,
    required this.sort,
    this.groupId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || subId != null) {
      map['sub_id'] = Variable<int>(subId);
    }
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['cms_variant'] = Variable<String>(cmsVariant);
    if (!nullToAbsent || endpoint != null) {
      map['endpoint'] = Variable<String>(endpoint);
    }
    if (!nullToAbsent || extRaw != null) {
      map['ext_raw'] = Variable<String>(extRaw);
    }
    if (!nullToAbsent || extUrl != null) {
      map['ext_url'] = Variable<String>(extUrl);
    }
    if (!nullToAbsent || sourceUrl != null) {
      map['source_url'] = Variable<String>(sourceUrl);
    }
    if (!nullToAbsent || jarRef != null) {
      map['jar_ref'] = Variable<String>(jarRef);
    }
    map['caps_searchable'] = Variable<bool>(capsSearchable);
    map['caps_quick_search'] = Variable<bool>(capsQuickSearch);
    map['caps_filterable'] = Variable<bool>(capsFilterable);
    map['caps_changeable'] = Variable<bool>(capsChangeable);
    if (!nullToAbsent || headers != null) {
      map['headers'] = Variable<String>(headers);
    }
    if (!nullToAbsent || timeoutSec != null) {
      map['timeout_sec'] = Variable<int>(timeoutSec);
    }
    if (!nullToAbsent || unsupportedReason != null) {
      map['unsupported_reason'] = Variable<String>(unsupportedReason);
    }
    map['enabled'] = Variable<bool>(enabled);
    map['sort'] = Variable<int>(sort);
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    return map;
  }

  SourceDefsCompanion toCompanion(bool nullToAbsent) {
    return SourceDefsCompanion(
      key: Value(key),
      subId: subId == null && nullToAbsent
          ? const Value.absent()
          : Value(subId),
      name: Value(name),
      kind: Value(kind),
      cmsVariant: Value(cmsVariant),
      endpoint: endpoint == null && nullToAbsent
          ? const Value.absent()
          : Value(endpoint),
      extRaw: extRaw == null && nullToAbsent
          ? const Value.absent()
          : Value(extRaw),
      extUrl: extUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(extUrl),
      sourceUrl: sourceUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceUrl),
      jarRef: jarRef == null && nullToAbsent
          ? const Value.absent()
          : Value(jarRef),
      capsSearchable: Value(capsSearchable),
      capsQuickSearch: Value(capsQuickSearch),
      capsFilterable: Value(capsFilterable),
      capsChangeable: Value(capsChangeable),
      headers: headers == null && nullToAbsent
          ? const Value.absent()
          : Value(headers),
      timeoutSec: timeoutSec == null && nullToAbsent
          ? const Value.absent()
          : Value(timeoutSec),
      unsupportedReason: unsupportedReason == null && nullToAbsent
          ? const Value.absent()
          : Value(unsupportedReason),
      enabled: Value(enabled),
      sort: Value(sort),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
    );
  }

  factory SourceDefRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SourceDefRow(
      key: serializer.fromJson<String>(json['key']),
      subId: serializer.fromJson<int?>(json['subId']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      cmsVariant: serializer.fromJson<String>(json['cmsVariant']),
      endpoint: serializer.fromJson<String?>(json['endpoint']),
      extRaw: serializer.fromJson<String?>(json['extRaw']),
      extUrl: serializer.fromJson<String?>(json['extUrl']),
      sourceUrl: serializer.fromJson<String?>(json['sourceUrl']),
      jarRef: serializer.fromJson<String?>(json['jarRef']),
      capsSearchable: serializer.fromJson<bool>(json['capsSearchable']),
      capsQuickSearch: serializer.fromJson<bool>(json['capsQuickSearch']),
      capsFilterable: serializer.fromJson<bool>(json['capsFilterable']),
      capsChangeable: serializer.fromJson<bool>(json['capsChangeable']),
      headers: serializer.fromJson<String?>(json['headers']),
      timeoutSec: serializer.fromJson<int?>(json['timeoutSec']),
      unsupportedReason: serializer.fromJson<String?>(
        json['unsupportedReason'],
      ),
      enabled: serializer.fromJson<bool>(json['enabled']),
      sort: serializer.fromJson<int>(json['sort']),
      groupId: serializer.fromJson<String?>(json['groupId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'subId': serializer.toJson<int?>(subId),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'cmsVariant': serializer.toJson<String>(cmsVariant),
      'endpoint': serializer.toJson<String?>(endpoint),
      'extRaw': serializer.toJson<String?>(extRaw),
      'extUrl': serializer.toJson<String?>(extUrl),
      'sourceUrl': serializer.toJson<String?>(sourceUrl),
      'jarRef': serializer.toJson<String?>(jarRef),
      'capsSearchable': serializer.toJson<bool>(capsSearchable),
      'capsQuickSearch': serializer.toJson<bool>(capsQuickSearch),
      'capsFilterable': serializer.toJson<bool>(capsFilterable),
      'capsChangeable': serializer.toJson<bool>(capsChangeable),
      'headers': serializer.toJson<String?>(headers),
      'timeoutSec': serializer.toJson<int?>(timeoutSec),
      'unsupportedReason': serializer.toJson<String?>(unsupportedReason),
      'enabled': serializer.toJson<bool>(enabled),
      'sort': serializer.toJson<int>(sort),
      'groupId': serializer.toJson<String?>(groupId),
    };
  }

  SourceDefRow copyWith({
    String? key,
    Value<int?> subId = const Value.absent(),
    String? name,
    String? kind,
    String? cmsVariant,
    Value<String?> endpoint = const Value.absent(),
    Value<String?> extRaw = const Value.absent(),
    Value<String?> extUrl = const Value.absent(),
    Value<String?> sourceUrl = const Value.absent(),
    Value<String?> jarRef = const Value.absent(),
    bool? capsSearchable,
    bool? capsQuickSearch,
    bool? capsFilterable,
    bool? capsChangeable,
    Value<String?> headers = const Value.absent(),
    Value<int?> timeoutSec = const Value.absent(),
    Value<String?> unsupportedReason = const Value.absent(),
    bool? enabled,
    int? sort,
    Value<String?> groupId = const Value.absent(),
  }) => SourceDefRow(
    key: key ?? this.key,
    subId: subId.present ? subId.value : this.subId,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    cmsVariant: cmsVariant ?? this.cmsVariant,
    endpoint: endpoint.present ? endpoint.value : this.endpoint,
    extRaw: extRaw.present ? extRaw.value : this.extRaw,
    extUrl: extUrl.present ? extUrl.value : this.extUrl,
    sourceUrl: sourceUrl.present ? sourceUrl.value : this.sourceUrl,
    jarRef: jarRef.present ? jarRef.value : this.jarRef,
    capsSearchable: capsSearchable ?? this.capsSearchable,
    capsQuickSearch: capsQuickSearch ?? this.capsQuickSearch,
    capsFilterable: capsFilterable ?? this.capsFilterable,
    capsChangeable: capsChangeable ?? this.capsChangeable,
    headers: headers.present ? headers.value : this.headers,
    timeoutSec: timeoutSec.present ? timeoutSec.value : this.timeoutSec,
    unsupportedReason: unsupportedReason.present
        ? unsupportedReason.value
        : this.unsupportedReason,
    enabled: enabled ?? this.enabled,
    sort: sort ?? this.sort,
    groupId: groupId.present ? groupId.value : this.groupId,
  );
  SourceDefRow copyWithCompanion(SourceDefsCompanion data) {
    return SourceDefRow(
      key: data.key.present ? data.key.value : this.key,
      subId: data.subId.present ? data.subId.value : this.subId,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      cmsVariant: data.cmsVariant.present
          ? data.cmsVariant.value
          : this.cmsVariant,
      endpoint: data.endpoint.present ? data.endpoint.value : this.endpoint,
      extRaw: data.extRaw.present ? data.extRaw.value : this.extRaw,
      extUrl: data.extUrl.present ? data.extUrl.value : this.extUrl,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
      jarRef: data.jarRef.present ? data.jarRef.value : this.jarRef,
      capsSearchable: data.capsSearchable.present
          ? data.capsSearchable.value
          : this.capsSearchable,
      capsQuickSearch: data.capsQuickSearch.present
          ? data.capsQuickSearch.value
          : this.capsQuickSearch,
      capsFilterable: data.capsFilterable.present
          ? data.capsFilterable.value
          : this.capsFilterable,
      capsChangeable: data.capsChangeable.present
          ? data.capsChangeable.value
          : this.capsChangeable,
      headers: data.headers.present ? data.headers.value : this.headers,
      timeoutSec: data.timeoutSec.present
          ? data.timeoutSec.value
          : this.timeoutSec,
      unsupportedReason: data.unsupportedReason.present
          ? data.unsupportedReason.value
          : this.unsupportedReason,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      sort: data.sort.present ? data.sort.value : this.sort,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SourceDefRow(')
          ..write('key: $key, ')
          ..write('subId: $subId, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('cmsVariant: $cmsVariant, ')
          ..write('endpoint: $endpoint, ')
          ..write('extRaw: $extRaw, ')
          ..write('extUrl: $extUrl, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('jarRef: $jarRef, ')
          ..write('capsSearchable: $capsSearchable, ')
          ..write('capsQuickSearch: $capsQuickSearch, ')
          ..write('capsFilterable: $capsFilterable, ')
          ..write('capsChangeable: $capsChangeable, ')
          ..write('headers: $headers, ')
          ..write('timeoutSec: $timeoutSec, ')
          ..write('unsupportedReason: $unsupportedReason, ')
          ..write('enabled: $enabled, ')
          ..write('sort: $sort, ')
          ..write('groupId: $groupId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    key,
    subId,
    name,
    kind,
    cmsVariant,
    endpoint,
    extRaw,
    extUrl,
    sourceUrl,
    jarRef,
    capsSearchable,
    capsQuickSearch,
    capsFilterable,
    capsChangeable,
    headers,
    timeoutSec,
    unsupportedReason,
    enabled,
    sort,
    groupId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SourceDefRow &&
          other.key == this.key &&
          other.subId == this.subId &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.cmsVariant == this.cmsVariant &&
          other.endpoint == this.endpoint &&
          other.extRaw == this.extRaw &&
          other.extUrl == this.extUrl &&
          other.sourceUrl == this.sourceUrl &&
          other.jarRef == this.jarRef &&
          other.capsSearchable == this.capsSearchable &&
          other.capsQuickSearch == this.capsQuickSearch &&
          other.capsFilterable == this.capsFilterable &&
          other.capsChangeable == this.capsChangeable &&
          other.headers == this.headers &&
          other.timeoutSec == this.timeoutSec &&
          other.unsupportedReason == this.unsupportedReason &&
          other.enabled == this.enabled &&
          other.sort == this.sort &&
          other.groupId == this.groupId);
}

class SourceDefsCompanion extends UpdateCompanion<SourceDefRow> {
  final Value<String> key;
  final Value<int?> subId;
  final Value<String> name;
  final Value<String> kind;
  final Value<String> cmsVariant;
  final Value<String?> endpoint;
  final Value<String?> extRaw;
  final Value<String?> extUrl;
  final Value<String?> sourceUrl;
  final Value<String?> jarRef;
  final Value<bool> capsSearchable;
  final Value<bool> capsQuickSearch;
  final Value<bool> capsFilterable;
  final Value<bool> capsChangeable;
  final Value<String?> headers;
  final Value<int?> timeoutSec;
  final Value<String?> unsupportedReason;
  final Value<bool> enabled;
  final Value<int> sort;
  final Value<String?> groupId;
  final Value<int> rowid;
  const SourceDefsCompanion({
    this.key = const Value.absent(),
    this.subId = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.cmsVariant = const Value.absent(),
    this.endpoint = const Value.absent(),
    this.extRaw = const Value.absent(),
    this.extUrl = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.jarRef = const Value.absent(),
    this.capsSearchable = const Value.absent(),
    this.capsQuickSearch = const Value.absent(),
    this.capsFilterable = const Value.absent(),
    this.capsChangeable = const Value.absent(),
    this.headers = const Value.absent(),
    this.timeoutSec = const Value.absent(),
    this.unsupportedReason = const Value.absent(),
    this.enabled = const Value.absent(),
    this.sort = const Value.absent(),
    this.groupId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SourceDefsCompanion.insert({
    required String key,
    this.subId = const Value.absent(),
    required String name,
    required String kind,
    this.cmsVariant = const Value.absent(),
    this.endpoint = const Value.absent(),
    this.extRaw = const Value.absent(),
    this.extUrl = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.jarRef = const Value.absent(),
    this.capsSearchable = const Value.absent(),
    this.capsQuickSearch = const Value.absent(),
    this.capsFilterable = const Value.absent(),
    this.capsChangeable = const Value.absent(),
    this.headers = const Value.absent(),
    this.timeoutSec = const Value.absent(),
    this.unsupportedReason = const Value.absent(),
    this.enabled = const Value.absent(),
    this.sort = const Value.absent(),
    this.groupId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       name = Value(name),
       kind = Value(kind);
  static Insertable<SourceDefRow> custom({
    Expression<String>? key,
    Expression<int>? subId,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<String>? cmsVariant,
    Expression<String>? endpoint,
    Expression<String>? extRaw,
    Expression<String>? extUrl,
    Expression<String>? sourceUrl,
    Expression<String>? jarRef,
    Expression<bool>? capsSearchable,
    Expression<bool>? capsQuickSearch,
    Expression<bool>? capsFilterable,
    Expression<bool>? capsChangeable,
    Expression<String>? headers,
    Expression<int>? timeoutSec,
    Expression<String>? unsupportedReason,
    Expression<bool>? enabled,
    Expression<int>? sort,
    Expression<String>? groupId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (subId != null) 'sub_id': subId,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (cmsVariant != null) 'cms_variant': cmsVariant,
      if (endpoint != null) 'endpoint': endpoint,
      if (extRaw != null) 'ext_raw': extRaw,
      if (extUrl != null) 'ext_url': extUrl,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (jarRef != null) 'jar_ref': jarRef,
      if (capsSearchable != null) 'caps_searchable': capsSearchable,
      if (capsQuickSearch != null) 'caps_quick_search': capsQuickSearch,
      if (capsFilterable != null) 'caps_filterable': capsFilterable,
      if (capsChangeable != null) 'caps_changeable': capsChangeable,
      if (headers != null) 'headers': headers,
      if (timeoutSec != null) 'timeout_sec': timeoutSec,
      if (unsupportedReason != null) 'unsupported_reason': unsupportedReason,
      if (enabled != null) 'enabled': enabled,
      if (sort != null) 'sort': sort,
      if (groupId != null) 'group_id': groupId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SourceDefsCompanion copyWith({
    Value<String>? key,
    Value<int?>? subId,
    Value<String>? name,
    Value<String>? kind,
    Value<String>? cmsVariant,
    Value<String?>? endpoint,
    Value<String?>? extRaw,
    Value<String?>? extUrl,
    Value<String?>? sourceUrl,
    Value<String?>? jarRef,
    Value<bool>? capsSearchable,
    Value<bool>? capsQuickSearch,
    Value<bool>? capsFilterable,
    Value<bool>? capsChangeable,
    Value<String?>? headers,
    Value<int?>? timeoutSec,
    Value<String?>? unsupportedReason,
    Value<bool>? enabled,
    Value<int>? sort,
    Value<String?>? groupId,
    Value<int>? rowid,
  }) {
    return SourceDefsCompanion(
      key: key ?? this.key,
      subId: subId ?? this.subId,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      cmsVariant: cmsVariant ?? this.cmsVariant,
      endpoint: endpoint ?? this.endpoint,
      extRaw: extRaw ?? this.extRaw,
      extUrl: extUrl ?? this.extUrl,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      jarRef: jarRef ?? this.jarRef,
      capsSearchable: capsSearchable ?? this.capsSearchable,
      capsQuickSearch: capsQuickSearch ?? this.capsQuickSearch,
      capsFilterable: capsFilterable ?? this.capsFilterable,
      capsChangeable: capsChangeable ?? this.capsChangeable,
      headers: headers ?? this.headers,
      timeoutSec: timeoutSec ?? this.timeoutSec,
      unsupportedReason: unsupportedReason ?? this.unsupportedReason,
      enabled: enabled ?? this.enabled,
      sort: sort ?? this.sort,
      groupId: groupId ?? this.groupId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (subId.present) {
      map['sub_id'] = Variable<int>(subId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (cmsVariant.present) {
      map['cms_variant'] = Variable<String>(cmsVariant.value);
    }
    if (endpoint.present) {
      map['endpoint'] = Variable<String>(endpoint.value);
    }
    if (extRaw.present) {
      map['ext_raw'] = Variable<String>(extRaw.value);
    }
    if (extUrl.present) {
      map['ext_url'] = Variable<String>(extUrl.value);
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    if (jarRef.present) {
      map['jar_ref'] = Variable<String>(jarRef.value);
    }
    if (capsSearchable.present) {
      map['caps_searchable'] = Variable<bool>(capsSearchable.value);
    }
    if (capsQuickSearch.present) {
      map['caps_quick_search'] = Variable<bool>(capsQuickSearch.value);
    }
    if (capsFilterable.present) {
      map['caps_filterable'] = Variable<bool>(capsFilterable.value);
    }
    if (capsChangeable.present) {
      map['caps_changeable'] = Variable<bool>(capsChangeable.value);
    }
    if (headers.present) {
      map['headers'] = Variable<String>(headers.value);
    }
    if (timeoutSec.present) {
      map['timeout_sec'] = Variable<int>(timeoutSec.value);
    }
    if (unsupportedReason.present) {
      map['unsupported_reason'] = Variable<String>(unsupportedReason.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (sort.present) {
      map['sort'] = Variable<int>(sort.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SourceDefsCompanion(')
          ..write('key: $key, ')
          ..write('subId: $subId, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('cmsVariant: $cmsVariant, ')
          ..write('endpoint: $endpoint, ')
          ..write('extRaw: $extRaw, ')
          ..write('extUrl: $extUrl, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('jarRef: $jarRef, ')
          ..write('capsSearchable: $capsSearchable, ')
          ..write('capsQuickSearch: $capsQuickSearch, ')
          ..write('capsFilterable: $capsFilterable, ')
          ..write('capsChangeable: $capsChangeable, ')
          ..write('headers: $headers, ')
          ..write('timeoutSec: $timeoutSec, ')
          ..write('unsupportedReason: $unsupportedReason, ')
          ..write('enabled: $enabled, ')
          ..write('sort: $sort, ')
          ..write('groupId: $groupId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkSnapshotsTable extends WorkSnapshots
    with TableInfo<$WorkSnapshotsTable, WorkSnapshotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _workKeyMeta = const VerificationMeta(
    'workKey',
  );
  @override
  late final GeneratedColumn<String> workKey = GeneratedColumn<String>(
    'work_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceKeyMeta = const VerificationMeta(
    'sourceKey',
  );
  @override
  late final GeneratedColumn<String> sourceKey = GeneratedColumn<String>(
    'source_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _posterPathMeta = const VerificationMeta(
    'posterPath',
  );
  @override
  late final GeneratedColumn<String> posterPath = GeneratedColumn<String>(
    'poster_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remarksMeta = const VerificationMeta(
    'remarks',
  );
  @override
  late final GeneratedColumn<String> remarks = GeneratedColumn<String>(
    'remarks',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<String> year = GeneratedColumn<String>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _areaMeta = const VerificationMeta('area');
  @override
  late final GeneratedColumn<String> area = GeneratedColumn<String>(
    'area',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
    'genre',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<String> score = GeneratedColumn<String>(
    'score',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawMeta = const VerificationMeta('raw');
  @override
  late final GeneratedColumn<String> raw = GeneratedColumn<String>(
    'raw',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    workKey,
    sourceKey,
    title,
    posterPath,
    remarks,
    year,
    area,
    genre,
    score,
    raw,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'work_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkSnapshotRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('work_key')) {
      context.handle(
        _workKeyMeta,
        workKey.isAcceptableOrUnknown(data['work_key']!, _workKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_workKeyMeta);
    }
    if (data.containsKey('source_key')) {
      context.handle(
        _sourceKeyMeta,
        sourceKey.isAcceptableOrUnknown(data['source_key']!, _sourceKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceKeyMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('poster_path')) {
      context.handle(
        _posterPathMeta,
        posterPath.isAcceptableOrUnknown(data['poster_path']!, _posterPathMeta),
      );
    }
    if (data.containsKey('remarks')) {
      context.handle(
        _remarksMeta,
        remarks.isAcceptableOrUnknown(data['remarks']!, _remarksMeta),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('area')) {
      context.handle(
        _areaMeta,
        area.isAcceptableOrUnknown(data['area']!, _areaMeta),
      );
    }
    if (data.containsKey('genre')) {
      context.handle(
        _genreMeta,
        genre.isAcceptableOrUnknown(data['genre']!, _genreMeta),
      );
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    }
    if (data.containsKey('raw')) {
      context.handle(
        _rawMeta,
        raw.isAcceptableOrUnknown(data['raw']!, _rawMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {workKey};
  @override
  WorkSnapshotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkSnapshotRow(
      workKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work_key'],
      )!,
      sourceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_key'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      posterPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poster_path'],
      ),
      remarks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remarks'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}year'],
      ),
      area: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}area'],
      ),
      genre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre'],
      ),
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}score'],
      ),
      raw: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw'],
      ),
    );
  }

  @override
  $WorkSnapshotsTable createAlias(String alias) {
    return $WorkSnapshotsTable(attachedDatabase, alias);
  }
}

class WorkSnapshotRow extends DataClass implements Insertable<WorkSnapshotRow> {
  final String workKey;
  final String sourceKey;
  final String title;
  final String? posterPath;
  final String? remarks;
  final String? year;
  final String? area;
  final String? genre;
  final String? score;
  final String? raw;
  const WorkSnapshotRow({
    required this.workKey,
    required this.sourceKey,
    required this.title,
    this.posterPath,
    this.remarks,
    this.year,
    this.area,
    this.genre,
    this.score,
    this.raw,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['work_key'] = Variable<String>(workKey);
    map['source_key'] = Variable<String>(sourceKey);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || posterPath != null) {
      map['poster_path'] = Variable<String>(posterPath);
    }
    if (!nullToAbsent || remarks != null) {
      map['remarks'] = Variable<String>(remarks);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<String>(year);
    }
    if (!nullToAbsent || area != null) {
      map['area'] = Variable<String>(area);
    }
    if (!nullToAbsent || genre != null) {
      map['genre'] = Variable<String>(genre);
    }
    if (!nullToAbsent || score != null) {
      map['score'] = Variable<String>(score);
    }
    if (!nullToAbsent || raw != null) {
      map['raw'] = Variable<String>(raw);
    }
    return map;
  }

  WorkSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return WorkSnapshotsCompanion(
      workKey: Value(workKey),
      sourceKey: Value(sourceKey),
      title: Value(title),
      posterPath: posterPath == null && nullToAbsent
          ? const Value.absent()
          : Value(posterPath),
      remarks: remarks == null && nullToAbsent
          ? const Value.absent()
          : Value(remarks),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      area: area == null && nullToAbsent ? const Value.absent() : Value(area),
      genre: genre == null && nullToAbsent
          ? const Value.absent()
          : Value(genre),
      score: score == null && nullToAbsent
          ? const Value.absent()
          : Value(score),
      raw: raw == null && nullToAbsent ? const Value.absent() : Value(raw),
    );
  }

  factory WorkSnapshotRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkSnapshotRow(
      workKey: serializer.fromJson<String>(json['workKey']),
      sourceKey: serializer.fromJson<String>(json['sourceKey']),
      title: serializer.fromJson<String>(json['title']),
      posterPath: serializer.fromJson<String?>(json['posterPath']),
      remarks: serializer.fromJson<String?>(json['remarks']),
      year: serializer.fromJson<String?>(json['year']),
      area: serializer.fromJson<String?>(json['area']),
      genre: serializer.fromJson<String?>(json['genre']),
      score: serializer.fromJson<String?>(json['score']),
      raw: serializer.fromJson<String?>(json['raw']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'workKey': serializer.toJson<String>(workKey),
      'sourceKey': serializer.toJson<String>(sourceKey),
      'title': serializer.toJson<String>(title),
      'posterPath': serializer.toJson<String?>(posterPath),
      'remarks': serializer.toJson<String?>(remarks),
      'year': serializer.toJson<String?>(year),
      'area': serializer.toJson<String?>(area),
      'genre': serializer.toJson<String?>(genre),
      'score': serializer.toJson<String?>(score),
      'raw': serializer.toJson<String?>(raw),
    };
  }

  WorkSnapshotRow copyWith({
    String? workKey,
    String? sourceKey,
    String? title,
    Value<String?> posterPath = const Value.absent(),
    Value<String?> remarks = const Value.absent(),
    Value<String?> year = const Value.absent(),
    Value<String?> area = const Value.absent(),
    Value<String?> genre = const Value.absent(),
    Value<String?> score = const Value.absent(),
    Value<String?> raw = const Value.absent(),
  }) => WorkSnapshotRow(
    workKey: workKey ?? this.workKey,
    sourceKey: sourceKey ?? this.sourceKey,
    title: title ?? this.title,
    posterPath: posterPath.present ? posterPath.value : this.posterPath,
    remarks: remarks.present ? remarks.value : this.remarks,
    year: year.present ? year.value : this.year,
    area: area.present ? area.value : this.area,
    genre: genre.present ? genre.value : this.genre,
    score: score.present ? score.value : this.score,
    raw: raw.present ? raw.value : this.raw,
  );
  WorkSnapshotRow copyWithCompanion(WorkSnapshotsCompanion data) {
    return WorkSnapshotRow(
      workKey: data.workKey.present ? data.workKey.value : this.workKey,
      sourceKey: data.sourceKey.present ? data.sourceKey.value : this.sourceKey,
      title: data.title.present ? data.title.value : this.title,
      posterPath: data.posterPath.present
          ? data.posterPath.value
          : this.posterPath,
      remarks: data.remarks.present ? data.remarks.value : this.remarks,
      year: data.year.present ? data.year.value : this.year,
      area: data.area.present ? data.area.value : this.area,
      genre: data.genre.present ? data.genre.value : this.genre,
      score: data.score.present ? data.score.value : this.score,
      raw: data.raw.present ? data.raw.value : this.raw,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkSnapshotRow(')
          ..write('workKey: $workKey, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('title: $title, ')
          ..write('posterPath: $posterPath, ')
          ..write('remarks: $remarks, ')
          ..write('year: $year, ')
          ..write('area: $area, ')
          ..write('genre: $genre, ')
          ..write('score: $score, ')
          ..write('raw: $raw')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    workKey,
    sourceKey,
    title,
    posterPath,
    remarks,
    year,
    area,
    genre,
    score,
    raw,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkSnapshotRow &&
          other.workKey == this.workKey &&
          other.sourceKey == this.sourceKey &&
          other.title == this.title &&
          other.posterPath == this.posterPath &&
          other.remarks == this.remarks &&
          other.year == this.year &&
          other.area == this.area &&
          other.genre == this.genre &&
          other.score == this.score &&
          other.raw == this.raw);
}

class WorkSnapshotsCompanion extends UpdateCompanion<WorkSnapshotRow> {
  final Value<String> workKey;
  final Value<String> sourceKey;
  final Value<String> title;
  final Value<String?> posterPath;
  final Value<String?> remarks;
  final Value<String?> year;
  final Value<String?> area;
  final Value<String?> genre;
  final Value<String?> score;
  final Value<String?> raw;
  final Value<int> rowid;
  const WorkSnapshotsCompanion({
    this.workKey = const Value.absent(),
    this.sourceKey = const Value.absent(),
    this.title = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.remarks = const Value.absent(),
    this.year = const Value.absent(),
    this.area = const Value.absent(),
    this.genre = const Value.absent(),
    this.score = const Value.absent(),
    this.raw = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkSnapshotsCompanion.insert({
    required String workKey,
    required String sourceKey,
    required String title,
    this.posterPath = const Value.absent(),
    this.remarks = const Value.absent(),
    this.year = const Value.absent(),
    this.area = const Value.absent(),
    this.genre = const Value.absent(),
    this.score = const Value.absent(),
    this.raw = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : workKey = Value(workKey),
       sourceKey = Value(sourceKey),
       title = Value(title);
  static Insertable<WorkSnapshotRow> custom({
    Expression<String>? workKey,
    Expression<String>? sourceKey,
    Expression<String>? title,
    Expression<String>? posterPath,
    Expression<String>? remarks,
    Expression<String>? year,
    Expression<String>? area,
    Expression<String>? genre,
    Expression<String>? score,
    Expression<String>? raw,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (workKey != null) 'work_key': workKey,
      if (sourceKey != null) 'source_key': sourceKey,
      if (title != null) 'title': title,
      if (posterPath != null) 'poster_path': posterPath,
      if (remarks != null) 'remarks': remarks,
      if (year != null) 'year': year,
      if (area != null) 'area': area,
      if (genre != null) 'genre': genre,
      if (score != null) 'score': score,
      if (raw != null) 'raw': raw,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkSnapshotsCompanion copyWith({
    Value<String>? workKey,
    Value<String>? sourceKey,
    Value<String>? title,
    Value<String?>? posterPath,
    Value<String?>? remarks,
    Value<String?>? year,
    Value<String?>? area,
    Value<String?>? genre,
    Value<String?>? score,
    Value<String?>? raw,
    Value<int>? rowid,
  }) {
    return WorkSnapshotsCompanion(
      workKey: workKey ?? this.workKey,
      sourceKey: sourceKey ?? this.sourceKey,
      title: title ?? this.title,
      posterPath: posterPath ?? this.posterPath,
      remarks: remarks ?? this.remarks,
      year: year ?? this.year,
      area: area ?? this.area,
      genre: genre ?? this.genre,
      score: score ?? this.score,
      raw: raw ?? this.raw,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (workKey.present) {
      map['work_key'] = Variable<String>(workKey.value);
    }
    if (sourceKey.present) {
      map['source_key'] = Variable<String>(sourceKey.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (posterPath.present) {
      map['poster_path'] = Variable<String>(posterPath.value);
    }
    if (remarks.present) {
      map['remarks'] = Variable<String>(remarks.value);
    }
    if (year.present) {
      map['year'] = Variable<String>(year.value);
    }
    if (area.present) {
      map['area'] = Variable<String>(area.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (score.present) {
      map['score'] = Variable<String>(score.value);
    }
    if (raw.present) {
      map['raw'] = Variable<String>(raw.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkSnapshotsCompanion(')
          ..write('workKey: $workKey, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('title: $title, ')
          ..write('posterPath: $posterPath, ')
          ..write('remarks: $remarks, ')
          ..write('year: $year, ')
          ..write('area: $area, ')
          ..write('genre: $genre, ')
          ..write('score: $score, ')
          ..write('raw: $raw, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlayRecordsTable extends PlayRecords
    with TableInfo<$PlayRecordsTable, PlayRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _workKeyMeta = const VerificationMeta(
    'workKey',
  );
  @override
  late final GeneratedColumn<String> workKey = GeneratedColumn<String>(
    'work_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES work_snapshots (work_key) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sourceKeyMeta = const VerificationMeta(
    'sourceKey',
  );
  @override
  late final GeneratedColumn<String> sourceKey = GeneratedColumn<String>(
    'source_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _episodeIndexMeta = const VerificationMeta(
    'episodeIndex',
  );
  @override
  late final GeneratedColumn<int> episodeIndex = GeneratedColumn<int>(
    'episode_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineIdMeta = const VerificationMeta('lineId');
  @override
  late final GeneratedColumn<String> lineId = GeneratedColumn<String>(
    'line_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionSecMeta = const VerificationMeta(
    'positionSec',
  );
  @override
  late final GeneratedColumn<int> positionSec = GeneratedColumn<int>(
    'position_sec',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durationSecMeta = const VerificationMeta(
    'durationSec',
  );
  @override
  late final GeneratedColumn<int> durationSec = GeneratedColumn<int>(
    'duration_sec',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    workKey,
    sourceKey,
    episodeIndex,
    lineId,
    positionSec,
    durationSec,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'play_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlayRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('work_key')) {
      context.handle(
        _workKeyMeta,
        workKey.isAcceptableOrUnknown(data['work_key']!, _workKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_workKeyMeta);
    }
    if (data.containsKey('source_key')) {
      context.handle(
        _sourceKeyMeta,
        sourceKey.isAcceptableOrUnknown(data['source_key']!, _sourceKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceKeyMeta);
    }
    if (data.containsKey('episode_index')) {
      context.handle(
        _episodeIndexMeta,
        episodeIndex.isAcceptableOrUnknown(
          data['episode_index']!,
          _episodeIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_episodeIndexMeta);
    }
    if (data.containsKey('line_id')) {
      context.handle(
        _lineIdMeta,
        lineId.isAcceptableOrUnknown(data['line_id']!, _lineIdMeta),
      );
    }
    if (data.containsKey('position_sec')) {
      context.handle(
        _positionSecMeta,
        positionSec.isAcceptableOrUnknown(
          data['position_sec']!,
          _positionSecMeta,
        ),
      );
    }
    if (data.containsKey('duration_sec')) {
      context.handle(
        _durationSecMeta,
        durationSec.isAcceptableOrUnknown(
          data['duration_sec']!,
          _durationSecMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {workKey};
  @override
  PlayRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayRecordRow(
      workKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work_key'],
      )!,
      sourceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_key'],
      )!,
      episodeIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episode_index'],
      )!,
      lineId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}line_id'],
      ),
      positionSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_sec'],
      )!,
      durationSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_sec'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PlayRecordsTable createAlias(String alias) {
    return $PlayRecordsTable(attachedDatabase, alias);
  }
}

class PlayRecordRow extends DataClass implements Insertable<PlayRecordRow> {
  final String workKey;
  final String sourceKey;
  final int episodeIndex;
  final String? lineId;
  final int positionSec;
  final int durationSec;

  /// 跨端同步以最后播放时间戳为准（docs/07 §4.5）
  final int updatedAt;
  const PlayRecordRow({
    required this.workKey,
    required this.sourceKey,
    required this.episodeIndex,
    this.lineId,
    required this.positionSec,
    required this.durationSec,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['work_key'] = Variable<String>(workKey);
    map['source_key'] = Variable<String>(sourceKey);
    map['episode_index'] = Variable<int>(episodeIndex);
    if (!nullToAbsent || lineId != null) {
      map['line_id'] = Variable<String>(lineId);
    }
    map['position_sec'] = Variable<int>(positionSec);
    map['duration_sec'] = Variable<int>(durationSec);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  PlayRecordsCompanion toCompanion(bool nullToAbsent) {
    return PlayRecordsCompanion(
      workKey: Value(workKey),
      sourceKey: Value(sourceKey),
      episodeIndex: Value(episodeIndex),
      lineId: lineId == null && nullToAbsent
          ? const Value.absent()
          : Value(lineId),
      positionSec: Value(positionSec),
      durationSec: Value(durationSec),
      updatedAt: Value(updatedAt),
    );
  }

  factory PlayRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayRecordRow(
      workKey: serializer.fromJson<String>(json['workKey']),
      sourceKey: serializer.fromJson<String>(json['sourceKey']),
      episodeIndex: serializer.fromJson<int>(json['episodeIndex']),
      lineId: serializer.fromJson<String?>(json['lineId']),
      positionSec: serializer.fromJson<int>(json['positionSec']),
      durationSec: serializer.fromJson<int>(json['durationSec']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'workKey': serializer.toJson<String>(workKey),
      'sourceKey': serializer.toJson<String>(sourceKey),
      'episodeIndex': serializer.toJson<int>(episodeIndex),
      'lineId': serializer.toJson<String?>(lineId),
      'positionSec': serializer.toJson<int>(positionSec),
      'durationSec': serializer.toJson<int>(durationSec),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  PlayRecordRow copyWith({
    String? workKey,
    String? sourceKey,
    int? episodeIndex,
    Value<String?> lineId = const Value.absent(),
    int? positionSec,
    int? durationSec,
    int? updatedAt,
  }) => PlayRecordRow(
    workKey: workKey ?? this.workKey,
    sourceKey: sourceKey ?? this.sourceKey,
    episodeIndex: episodeIndex ?? this.episodeIndex,
    lineId: lineId.present ? lineId.value : this.lineId,
    positionSec: positionSec ?? this.positionSec,
    durationSec: durationSec ?? this.durationSec,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PlayRecordRow copyWithCompanion(PlayRecordsCompanion data) {
    return PlayRecordRow(
      workKey: data.workKey.present ? data.workKey.value : this.workKey,
      sourceKey: data.sourceKey.present ? data.sourceKey.value : this.sourceKey,
      episodeIndex: data.episodeIndex.present
          ? data.episodeIndex.value
          : this.episodeIndex,
      lineId: data.lineId.present ? data.lineId.value : this.lineId,
      positionSec: data.positionSec.present
          ? data.positionSec.value
          : this.positionSec,
      durationSec: data.durationSec.present
          ? data.durationSec.value
          : this.durationSec,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayRecordRow(')
          ..write('workKey: $workKey, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('episodeIndex: $episodeIndex, ')
          ..write('lineId: $lineId, ')
          ..write('positionSec: $positionSec, ')
          ..write('durationSec: $durationSec, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    workKey,
    sourceKey,
    episodeIndex,
    lineId,
    positionSec,
    durationSec,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayRecordRow &&
          other.workKey == this.workKey &&
          other.sourceKey == this.sourceKey &&
          other.episodeIndex == this.episodeIndex &&
          other.lineId == this.lineId &&
          other.positionSec == this.positionSec &&
          other.durationSec == this.durationSec &&
          other.updatedAt == this.updatedAt);
}

class PlayRecordsCompanion extends UpdateCompanion<PlayRecordRow> {
  final Value<String> workKey;
  final Value<String> sourceKey;
  final Value<int> episodeIndex;
  final Value<String?> lineId;
  final Value<int> positionSec;
  final Value<int> durationSec;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const PlayRecordsCompanion({
    this.workKey = const Value.absent(),
    this.sourceKey = const Value.absent(),
    this.episodeIndex = const Value.absent(),
    this.lineId = const Value.absent(),
    this.positionSec = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlayRecordsCompanion.insert({
    required String workKey,
    required String sourceKey,
    required int episodeIndex,
    this.lineId = const Value.absent(),
    this.positionSec = const Value.absent(),
    this.durationSec = const Value.absent(),
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : workKey = Value(workKey),
       sourceKey = Value(sourceKey),
       episodeIndex = Value(episodeIndex),
       updatedAt = Value(updatedAt);
  static Insertable<PlayRecordRow> custom({
    Expression<String>? workKey,
    Expression<String>? sourceKey,
    Expression<int>? episodeIndex,
    Expression<String>? lineId,
    Expression<int>? positionSec,
    Expression<int>? durationSec,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (workKey != null) 'work_key': workKey,
      if (sourceKey != null) 'source_key': sourceKey,
      if (episodeIndex != null) 'episode_index': episodeIndex,
      if (lineId != null) 'line_id': lineId,
      if (positionSec != null) 'position_sec': positionSec,
      if (durationSec != null) 'duration_sec': durationSec,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlayRecordsCompanion copyWith({
    Value<String>? workKey,
    Value<String>? sourceKey,
    Value<int>? episodeIndex,
    Value<String?>? lineId,
    Value<int>? positionSec,
    Value<int>? durationSec,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return PlayRecordsCompanion(
      workKey: workKey ?? this.workKey,
      sourceKey: sourceKey ?? this.sourceKey,
      episodeIndex: episodeIndex ?? this.episodeIndex,
      lineId: lineId ?? this.lineId,
      positionSec: positionSec ?? this.positionSec,
      durationSec: durationSec ?? this.durationSec,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (workKey.present) {
      map['work_key'] = Variable<String>(workKey.value);
    }
    if (sourceKey.present) {
      map['source_key'] = Variable<String>(sourceKey.value);
    }
    if (episodeIndex.present) {
      map['episode_index'] = Variable<int>(episodeIndex.value);
    }
    if (lineId.present) {
      map['line_id'] = Variable<String>(lineId.value);
    }
    if (positionSec.present) {
      map['position_sec'] = Variable<int>(positionSec.value);
    }
    if (durationSec.present) {
      map['duration_sec'] = Variable<int>(durationSec.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayRecordsCompanion(')
          ..write('workKey: $workKey, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('episodeIndex: $episodeIndex, ')
          ..write('lineId: $lineId, ')
          ..write('positionSec: $positionSec, ')
          ..write('durationSec: $durationSec, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FavoriteFoldersTable extends FavoriteFolders
    with TableInfo<$FavoriteFoldersTable, FavoriteFolderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoriteFoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortMeta = const VerificationMeta('sort');
  @override
  late final GeneratedColumn<int> sort = GeneratedColumn<int>(
    'sort',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, sort];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorite_folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<FavoriteFolderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort')) {
      context.handle(
        _sortMeta,
        sort.isAcceptableOrUnknown(data['sort']!, _sortMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FavoriteFolderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteFolderRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sort: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort'],
      )!,
    );
  }

  @override
  $FavoriteFoldersTable createAlias(String alias) {
    return $FavoriteFoldersTable(attachedDatabase, alias);
  }
}

class FavoriteFolderRow extends DataClass
    implements Insertable<FavoriteFolderRow> {
  final int id;
  final String name;
  final int sort;
  const FavoriteFolderRow({
    required this.id,
    required this.name,
    required this.sort,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['sort'] = Variable<int>(sort);
    return map;
  }

  FavoriteFoldersCompanion toCompanion(bool nullToAbsent) {
    return FavoriteFoldersCompanion(
      id: Value(id),
      name: Value(name),
      sort: Value(sort),
    );
  }

  factory FavoriteFolderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteFolderRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sort: serializer.fromJson<int>(json['sort']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'sort': serializer.toJson<int>(sort),
    };
  }

  FavoriteFolderRow copyWith({int? id, String? name, int? sort}) =>
      FavoriteFolderRow(
        id: id ?? this.id,
        name: name ?? this.name,
        sort: sort ?? this.sort,
      );
  FavoriteFolderRow copyWithCompanion(FavoriteFoldersCompanion data) {
    return FavoriteFolderRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sort: data.sort.present ? data.sort.value : this.sort,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteFolderRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sort: $sort')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, sort);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteFolderRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.sort == this.sort);
}

class FavoriteFoldersCompanion extends UpdateCompanion<FavoriteFolderRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> sort;
  const FavoriteFoldersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sort = const Value.absent(),
  });
  FavoriteFoldersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.sort = const Value.absent(),
  }) : name = Value(name);
  static Insertable<FavoriteFolderRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? sort,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sort != null) 'sort': sort,
    });
  }

  FavoriteFoldersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? sort,
  }) {
    return FavoriteFoldersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sort: sort ?? this.sort,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sort.present) {
      map['sort'] = Variable<int>(sort.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteFoldersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sort: $sort')
          ..write(')'))
        .toString();
  }
}

class $FavoritesTable extends Favorites
    with TableInfo<$FavoritesTable, FavoriteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _workKeyMeta = const VerificationMeta(
    'workKey',
  );
  @override
  late final GeneratedColumn<String> workKey = GeneratedColumn<String>(
    'work_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES work_snapshots (work_key) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _folderIdMeta = const VerificationMeta(
    'folderId',
  );
  @override
  late final GeneratedColumn<int> folderId = GeneratedColumn<int>(
    'folder_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES favorite_folders (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [workKey, folderId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites';
  @override
  VerificationContext validateIntegrity(
    Insertable<FavoriteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('work_key')) {
      context.handle(
        _workKeyMeta,
        workKey.isAcceptableOrUnknown(data['work_key']!, _workKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_workKeyMeta);
    }
    if (data.containsKey('folder_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {workKey};
  @override
  FavoriteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteRow(
      workKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work_key'],
      )!,
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}folder_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FavoritesTable createAlias(String alias) {
    return $FavoritesTable(attachedDatabase, alias);
  }
}

class FavoriteRow extends DataClass implements Insertable<FavoriteRow> {
  final String workKey;
  final int? folderId;
  final int createdAt;
  const FavoriteRow({
    required this.workKey,
    this.folderId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['work_key'] = Variable<String>(workKey);
    if (!nullToAbsent || folderId != null) {
      map['folder_id'] = Variable<int>(folderId);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  FavoritesCompanion toCompanion(bool nullToAbsent) {
    return FavoritesCompanion(
      workKey: Value(workKey),
      folderId: folderId == null && nullToAbsent
          ? const Value.absent()
          : Value(folderId),
      createdAt: Value(createdAt),
    );
  }

  factory FavoriteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteRow(
      workKey: serializer.fromJson<String>(json['workKey']),
      folderId: serializer.fromJson<int?>(json['folderId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'workKey': serializer.toJson<String>(workKey),
      'folderId': serializer.toJson<int?>(folderId),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  FavoriteRow copyWith({
    String? workKey,
    Value<int?> folderId = const Value.absent(),
    int? createdAt,
  }) => FavoriteRow(
    workKey: workKey ?? this.workKey,
    folderId: folderId.present ? folderId.value : this.folderId,
    createdAt: createdAt ?? this.createdAt,
  );
  FavoriteRow copyWithCompanion(FavoritesCompanion data) {
    return FavoriteRow(
      workKey: data.workKey.present ? data.workKey.value : this.workKey,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteRow(')
          ..write('workKey: $workKey, ')
          ..write('folderId: $folderId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(workKey, folderId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteRow &&
          other.workKey == this.workKey &&
          other.folderId == this.folderId &&
          other.createdAt == this.createdAt);
}

class FavoritesCompanion extends UpdateCompanion<FavoriteRow> {
  final Value<String> workKey;
  final Value<int?> folderId;
  final Value<int> createdAt;
  final Value<int> rowid;
  const FavoritesCompanion({
    this.workKey = const Value.absent(),
    this.folderId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavoritesCompanion.insert({
    required String workKey,
    this.folderId = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : workKey = Value(workKey),
       createdAt = Value(createdAt);
  static Insertable<FavoriteRow> custom({
    Expression<String>? workKey,
    Expression<int>? folderId,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (workKey != null) 'work_key': workKey,
      if (folderId != null) 'folder_id': folderId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavoritesCompanion copyWith({
    Value<String>? workKey,
    Value<int?>? folderId,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return FavoritesCompanion(
      workKey: workKey ?? this.workKey,
      folderId: folderId ?? this.folderId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (workKey.present) {
      map['work_key'] = Variable<String>(workKey.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<int>(folderId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesCompanion(')
          ..write('workKey: $workKey, ')
          ..write('folderId: $folderId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LiveChannelsTable extends LiveChannels
    with TableInfo<$LiveChannelsTable, LiveChannelRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LiveChannelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _logoMeta = const VerificationMeta('logo');
  @override
  late final GeneratedColumn<String> logo = GeneratedColumn<String>(
    'logo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _epgIdMeta = const VerificationMeta('epgId');
  @override
  late final GeneratedColumn<String> epgId = GeneratedColumn<String>(
    'epg_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tuneNoMeta = const VerificationMeta('tuneNo');
  @override
  late final GeneratedColumn<int> tuneNo = GeneratedColumn<int>(
    'tune_no',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortMeta = const VerificationMeta('sort');
  @override
  late final GeneratedColumn<int> sort = GeneratedColumn<int>(
    'sort',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    name,
    url,
    logo,
    epgId,
    tuneNo,
    sort,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'live_channels';
  @override
  VerificationContext validateIntegrity(
    Insertable<LiveChannelRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('logo')) {
      context.handle(
        _logoMeta,
        logo.isAcceptableOrUnknown(data['logo']!, _logoMeta),
      );
    }
    if (data.containsKey('epg_id')) {
      context.handle(
        _epgIdMeta,
        epgId.isAcceptableOrUnknown(data['epg_id']!, _epgIdMeta),
      );
    }
    if (data.containsKey('tune_no')) {
      context.handle(
        _tuneNoMeta,
        tuneNo.isAcceptableOrUnknown(data['tune_no']!, _tuneNoMeta),
      );
    }
    if (data.containsKey('sort')) {
      context.handle(
        _sortMeta,
        sort.isAcceptableOrUnknown(data['sort']!, _sortMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LiveChannelRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LiveChannelRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      logo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logo'],
      ),
      epgId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}epg_id'],
      ),
      tuneNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tune_no'],
      ),
      sort: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort'],
      )!,
    );
  }

  @override
  $LiveChannelsTable createAlias(String alias) {
    return $LiveChannelsTable(attachedDatabase, alias);
  }
}

class LiveChannelRow extends DataClass implements Insertable<LiveChannelRow> {
  final int id;
  final String groupId;
  final String name;
  final String url;
  final String? logo;
  final String? epgId;
  final int? tuneNo;
  final int sort;
  const LiveChannelRow({
    required this.id,
    required this.groupId,
    required this.name,
    required this.url,
    this.logo,
    this.epgId,
    this.tuneNo,
    required this.sort,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['group_id'] = Variable<String>(groupId);
    map['name'] = Variable<String>(name);
    map['url'] = Variable<String>(url);
    if (!nullToAbsent || logo != null) {
      map['logo'] = Variable<String>(logo);
    }
    if (!nullToAbsent || epgId != null) {
      map['epg_id'] = Variable<String>(epgId);
    }
    if (!nullToAbsent || tuneNo != null) {
      map['tune_no'] = Variable<int>(tuneNo);
    }
    map['sort'] = Variable<int>(sort);
    return map;
  }

  LiveChannelsCompanion toCompanion(bool nullToAbsent) {
    return LiveChannelsCompanion(
      id: Value(id),
      groupId: Value(groupId),
      name: Value(name),
      url: Value(url),
      logo: logo == null && nullToAbsent ? const Value.absent() : Value(logo),
      epgId: epgId == null && nullToAbsent
          ? const Value.absent()
          : Value(epgId),
      tuneNo: tuneNo == null && nullToAbsent
          ? const Value.absent()
          : Value(tuneNo),
      sort: Value(sort),
    );
  }

  factory LiveChannelRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LiveChannelRow(
      id: serializer.fromJson<int>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      name: serializer.fromJson<String>(json['name']),
      url: serializer.fromJson<String>(json['url']),
      logo: serializer.fromJson<String?>(json['logo']),
      epgId: serializer.fromJson<String?>(json['epgId']),
      tuneNo: serializer.fromJson<int?>(json['tuneNo']),
      sort: serializer.fromJson<int>(json['sort']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'groupId': serializer.toJson<String>(groupId),
      'name': serializer.toJson<String>(name),
      'url': serializer.toJson<String>(url),
      'logo': serializer.toJson<String?>(logo),
      'epgId': serializer.toJson<String?>(epgId),
      'tuneNo': serializer.toJson<int?>(tuneNo),
      'sort': serializer.toJson<int>(sort),
    };
  }

  LiveChannelRow copyWith({
    int? id,
    String? groupId,
    String? name,
    String? url,
    Value<String?> logo = const Value.absent(),
    Value<String?> epgId = const Value.absent(),
    Value<int?> tuneNo = const Value.absent(),
    int? sort,
  }) => LiveChannelRow(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    name: name ?? this.name,
    url: url ?? this.url,
    logo: logo.present ? logo.value : this.logo,
    epgId: epgId.present ? epgId.value : this.epgId,
    tuneNo: tuneNo.present ? tuneNo.value : this.tuneNo,
    sort: sort ?? this.sort,
  );
  LiveChannelRow copyWithCompanion(LiveChannelsCompanion data) {
    return LiveChannelRow(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      name: data.name.present ? data.name.value : this.name,
      url: data.url.present ? data.url.value : this.url,
      logo: data.logo.present ? data.logo.value : this.logo,
      epgId: data.epgId.present ? data.epgId.value : this.epgId,
      tuneNo: data.tuneNo.present ? data.tuneNo.value : this.tuneNo,
      sort: data.sort.present ? data.sort.value : this.sort,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LiveChannelRow(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('logo: $logo, ')
          ..write('epgId: $epgId, ')
          ..write('tuneNo: $tuneNo, ')
          ..write('sort: $sort')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, groupId, name, url, logo, epgId, tuneNo, sort);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LiveChannelRow &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.name == this.name &&
          other.url == this.url &&
          other.logo == this.logo &&
          other.epgId == this.epgId &&
          other.tuneNo == this.tuneNo &&
          other.sort == this.sort);
}

class LiveChannelsCompanion extends UpdateCompanion<LiveChannelRow> {
  final Value<int> id;
  final Value<String> groupId;
  final Value<String> name;
  final Value<String> url;
  final Value<String?> logo;
  final Value<String?> epgId;
  final Value<int?> tuneNo;
  final Value<int> sort;
  const LiveChannelsCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.name = const Value.absent(),
    this.url = const Value.absent(),
    this.logo = const Value.absent(),
    this.epgId = const Value.absent(),
    this.tuneNo = const Value.absent(),
    this.sort = const Value.absent(),
  });
  LiveChannelsCompanion.insert({
    this.id = const Value.absent(),
    required String groupId,
    required String name,
    required String url,
    this.logo = const Value.absent(),
    this.epgId = const Value.absent(),
    this.tuneNo = const Value.absent(),
    this.sort = const Value.absent(),
  }) : groupId = Value(groupId),
       name = Value(name),
       url = Value(url);
  static Insertable<LiveChannelRow> custom({
    Expression<int>? id,
    Expression<String>? groupId,
    Expression<String>? name,
    Expression<String>? url,
    Expression<String>? logo,
    Expression<String>? epgId,
    Expression<int>? tuneNo,
    Expression<int>? sort,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (name != null) 'name': name,
      if (url != null) 'url': url,
      if (logo != null) 'logo': logo,
      if (epgId != null) 'epg_id': epgId,
      if (tuneNo != null) 'tune_no': tuneNo,
      if (sort != null) 'sort': sort,
    });
  }

  LiveChannelsCompanion copyWith({
    Value<int>? id,
    Value<String>? groupId,
    Value<String>? name,
    Value<String>? url,
    Value<String?>? logo,
    Value<String?>? epgId,
    Value<int?>? tuneNo,
    Value<int>? sort,
  }) {
    return LiveChannelsCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      url: url ?? this.url,
      logo: logo ?? this.logo,
      epgId: epgId ?? this.epgId,
      tuneNo: tuneNo ?? this.tuneNo,
      sort: sort ?? this.sort,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (logo.present) {
      map['logo'] = Variable<String>(logo.value);
    }
    if (epgId.present) {
      map['epg_id'] = Variable<String>(epgId.value);
    }
    if (tuneNo.present) {
      map['tune_no'] = Variable<int>(tuneNo.value);
    }
    if (sort.present) {
      map['sort'] = Variable<int>(sort.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LiveChannelsCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('logo: $logo, ')
          ..write('epgId: $epgId, ')
          ..write('tuneNo: $tuneNo, ')
          ..write('sort: $sort')
          ..write(')'))
        .toString();
  }
}

class $HealthRecordsTable extends HealthRecords
    with TableInfo<$HealthRecordsTable, HealthRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HealthRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sourceKeyMeta = const VerificationMeta(
    'sourceKey',
  );
  @override
  late final GeneratedColumn<String> sourceKey = GeneratedColumn<String>(
    'source_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES source_defs ("key") ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<int> ts = GeneratedColumn<int>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latencyMsMeta = const VerificationMeta(
    'latencyMs',
  );
  @override
  late final GeneratedColumn<int> latencyMs = GeneratedColumn<int>(
    'latency_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _okMeta = const VerificationMeta('ok');
  @override
  late final GeneratedColumn<bool> ok = GeneratedColumn<bool>(
    'ok',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ok" IN (0, 1))',
    ),
  );
  static const VerificationMeta _failStageMeta = const VerificationMeta(
    'failStage',
  );
  @override
  late final GeneratedColumn<String> failStage = GeneratedColumn<String>(
    'fail_stage',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceKey,
    ts,
    latencyMs,
    ok,
    failStage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'health_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<HealthRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_key')) {
      context.handle(
        _sourceKeyMeta,
        sourceKey.isAcceptableOrUnknown(data['source_key']!, _sourceKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceKeyMeta);
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    } else if (isInserting) {
      context.missing(_tsMeta);
    }
    if (data.containsKey('latency_ms')) {
      context.handle(
        _latencyMsMeta,
        latencyMs.isAcceptableOrUnknown(data['latency_ms']!, _latencyMsMeta),
      );
    }
    if (data.containsKey('ok')) {
      context.handle(_okMeta, ok.isAcceptableOrUnknown(data['ok']!, _okMeta));
    } else if (isInserting) {
      context.missing(_okMeta);
    }
    if (data.containsKey('fail_stage')) {
      context.handle(
        _failStageMeta,
        failStage.isAcceptableOrUnknown(data['fail_stage']!, _failStageMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HealthRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HealthRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sourceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_key'],
      )!,
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ts'],
      )!,
      latencyMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}latency_ms'],
      ),
      ok: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ok'],
      )!,
      failStage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fail_stage'],
      ),
    );
  }

  @override
  $HealthRecordsTable createAlias(String alias) {
    return $HealthRecordsTable(attachedDatabase, alias);
  }
}

class HealthRecordRow extends DataClass implements Insertable<HealthRecordRow> {
  final int id;
  final String sourceKey;
  final int ts;
  final int? latencyMs;
  final bool ok;
  final String? failStage;
  const HealthRecordRow({
    required this.id,
    required this.sourceKey,
    required this.ts,
    this.latencyMs,
    required this.ok,
    this.failStage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source_key'] = Variable<String>(sourceKey);
    map['ts'] = Variable<int>(ts);
    if (!nullToAbsent || latencyMs != null) {
      map['latency_ms'] = Variable<int>(latencyMs);
    }
    map['ok'] = Variable<bool>(ok);
    if (!nullToAbsent || failStage != null) {
      map['fail_stage'] = Variable<String>(failStage);
    }
    return map;
  }

  HealthRecordsCompanion toCompanion(bool nullToAbsent) {
    return HealthRecordsCompanion(
      id: Value(id),
      sourceKey: Value(sourceKey),
      ts: Value(ts),
      latencyMs: latencyMs == null && nullToAbsent
          ? const Value.absent()
          : Value(latencyMs),
      ok: Value(ok),
      failStage: failStage == null && nullToAbsent
          ? const Value.absent()
          : Value(failStage),
    );
  }

  factory HealthRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HealthRecordRow(
      id: serializer.fromJson<int>(json['id']),
      sourceKey: serializer.fromJson<String>(json['sourceKey']),
      ts: serializer.fromJson<int>(json['ts']),
      latencyMs: serializer.fromJson<int?>(json['latencyMs']),
      ok: serializer.fromJson<bool>(json['ok']),
      failStage: serializer.fromJson<String?>(json['failStage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourceKey': serializer.toJson<String>(sourceKey),
      'ts': serializer.toJson<int>(ts),
      'latencyMs': serializer.toJson<int?>(latencyMs),
      'ok': serializer.toJson<bool>(ok),
      'failStage': serializer.toJson<String?>(failStage),
    };
  }

  HealthRecordRow copyWith({
    int? id,
    String? sourceKey,
    int? ts,
    Value<int?> latencyMs = const Value.absent(),
    bool? ok,
    Value<String?> failStage = const Value.absent(),
  }) => HealthRecordRow(
    id: id ?? this.id,
    sourceKey: sourceKey ?? this.sourceKey,
    ts: ts ?? this.ts,
    latencyMs: latencyMs.present ? latencyMs.value : this.latencyMs,
    ok: ok ?? this.ok,
    failStage: failStage.present ? failStage.value : this.failStage,
  );
  HealthRecordRow copyWithCompanion(HealthRecordsCompanion data) {
    return HealthRecordRow(
      id: data.id.present ? data.id.value : this.id,
      sourceKey: data.sourceKey.present ? data.sourceKey.value : this.sourceKey,
      ts: data.ts.present ? data.ts.value : this.ts,
      latencyMs: data.latencyMs.present ? data.latencyMs.value : this.latencyMs,
      ok: data.ok.present ? data.ok.value : this.ok,
      failStage: data.failStage.present ? data.failStage.value : this.failStage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HealthRecordRow(')
          ..write('id: $id, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('ts: $ts, ')
          ..write('latencyMs: $latencyMs, ')
          ..write('ok: $ok, ')
          ..write('failStage: $failStage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sourceKey, ts, latencyMs, ok, failStage);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HealthRecordRow &&
          other.id == this.id &&
          other.sourceKey == this.sourceKey &&
          other.ts == this.ts &&
          other.latencyMs == this.latencyMs &&
          other.ok == this.ok &&
          other.failStage == this.failStage);
}

class HealthRecordsCompanion extends UpdateCompanion<HealthRecordRow> {
  final Value<int> id;
  final Value<String> sourceKey;
  final Value<int> ts;
  final Value<int?> latencyMs;
  final Value<bool> ok;
  final Value<String?> failStage;
  const HealthRecordsCompanion({
    this.id = const Value.absent(),
    this.sourceKey = const Value.absent(),
    this.ts = const Value.absent(),
    this.latencyMs = const Value.absent(),
    this.ok = const Value.absent(),
    this.failStage = const Value.absent(),
  });
  HealthRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String sourceKey,
    required int ts,
    this.latencyMs = const Value.absent(),
    required bool ok,
    this.failStage = const Value.absent(),
  }) : sourceKey = Value(sourceKey),
       ts = Value(ts),
       ok = Value(ok);
  static Insertable<HealthRecordRow> custom({
    Expression<int>? id,
    Expression<String>? sourceKey,
    Expression<int>? ts,
    Expression<int>? latencyMs,
    Expression<bool>? ok,
    Expression<String>? failStage,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceKey != null) 'source_key': sourceKey,
      if (ts != null) 'ts': ts,
      if (latencyMs != null) 'latency_ms': latencyMs,
      if (ok != null) 'ok': ok,
      if (failStage != null) 'fail_stage': failStage,
    });
  }

  HealthRecordsCompanion copyWith({
    Value<int>? id,
    Value<String>? sourceKey,
    Value<int>? ts,
    Value<int?>? latencyMs,
    Value<bool>? ok,
    Value<String?>? failStage,
  }) {
    return HealthRecordsCompanion(
      id: id ?? this.id,
      sourceKey: sourceKey ?? this.sourceKey,
      ts: ts ?? this.ts,
      latencyMs: latencyMs ?? this.latencyMs,
      ok: ok ?? this.ok,
      failStage: failStage ?? this.failStage,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourceKey.present) {
      map['source_key'] = Variable<String>(sourceKey.value);
    }
    if (ts.present) {
      map['ts'] = Variable<int>(ts.value);
    }
    if (latencyMs.present) {
      map['latency_ms'] = Variable<int>(latencyMs.value);
    }
    if (ok.present) {
      map['ok'] = Variable<bool>(ok.value);
    }
    if (failStage.present) {
      map['fail_stage'] = Variable<String>(failStage.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HealthRecordsCompanion(')
          ..write('id: $id, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('ts: $ts, ')
          ..write('latencyMs: $latencyMs, ')
          ..write('ok: $ok, ')
          ..write('failStage: $failStage')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSettingRow extends DataClass implements Insertable<AppSettingRow> {
  final String key;
  final String value;
  const AppSettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSettingRow copyWith({String? key, String? value}) =>
      AppSettingRow(key: key ?? this.key, value: value ?? this.value);
  AppSettingRow copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$StarDatabase extends GeneratedDatabase {
  _$StarDatabase(QueryExecutor e) : super(e);
  $StarDatabaseManager get managers => $StarDatabaseManager(this);
  late final $SubscriptionsTable subscriptions = $SubscriptionsTable(this);
  late final $SourceDefsTable sourceDefs = $SourceDefsTable(this);
  late final $WorkSnapshotsTable workSnapshots = $WorkSnapshotsTable(this);
  late final $PlayRecordsTable playRecords = $PlayRecordsTable(this);
  late final $FavoriteFoldersTable favoriteFolders = $FavoriteFoldersTable(
    this,
  );
  late final $FavoritesTable favorites = $FavoritesTable(this);
  late final $LiveChannelsTable liveChannels = $LiveChannelsTable(this);
  late final $HealthRecordsTable healthRecords = $HealthRecordsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    subscriptions,
    sourceDefs,
    workSnapshots,
    playRecords,
    favoriteFolders,
    favorites,
    liveChannels,
    healthRecords,
    appSettings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'work_snapshots',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('play_records', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'work_snapshots',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('favorites', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'source_defs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('health_records', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$SubscriptionsTableCreateCompanionBuilder =
    SubscriptionsCompanion Function({
      Value<int> id,
      required String kind,
      Value<String?> url,
      Value<String?> etag,
      Value<int?> fetchedAt,
      Value<String?> raw,
    });
typedef $$SubscriptionsTableUpdateCompanionBuilder =
    SubscriptionsCompanion Function({
      Value<int> id,
      Value<String> kind,
      Value<String?> url,
      Value<String?> etag,
      Value<int?> fetchedAt,
      Value<String?> raw,
    });

final class $$SubscriptionsTableReferences
    extends
        BaseReferences<_$StarDatabase, $SubscriptionsTable, SubscriptionRow> {
  $$SubscriptionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$SourceDefsTable, List<SourceDefRow>>
  _sourceDefsRefsTable(_$StarDatabase db) => MultiTypedResultKey.fromTable(
    db.sourceDefs,
    aliasName: 'subscriptions__id__source_defs__sub_id',
  );

  $$SourceDefsTableProcessedTableManager get sourceDefsRefs {
    final manager = $$SourceDefsTableTableManager(
      $_db,
      $_db.sourceDefs,
    ).filter((f) => f.subId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sourceDefsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SubscriptionsTableFilterComposer
    extends Composer<_$StarDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get raw => $composableBuilder(
    column: $table.raw,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> sourceDefsRefs(
    Expression<bool> Function($$SourceDefsTableFilterComposer f) f,
  ) {
    final $$SourceDefsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sourceDefs,
      getReferencedColumn: (t) => t.subId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourceDefsTableFilterComposer(
            $db: $db,
            $table: $db.sourceDefs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SubscriptionsTableOrderingComposer
    extends Composer<_$StarDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get raw => $composableBuilder(
    column: $table.raw,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubscriptionsTableAnnotationComposer
    extends Composer<_$StarDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<int> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<String> get raw =>
      $composableBuilder(column: $table.raw, builder: (column) => column);

  Expression<T> sourceDefsRefs<T extends Object>(
    Expression<T> Function($$SourceDefsTableAnnotationComposer a) f,
  ) {
    final $$SourceDefsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sourceDefs,
      getReferencedColumn: (t) => t.subId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourceDefsTableAnnotationComposer(
            $db: $db,
            $table: $db.sourceDefs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SubscriptionsTableTableManager
    extends
        RootTableManager<
          _$StarDatabase,
          $SubscriptionsTable,
          SubscriptionRow,
          $$SubscriptionsTableFilterComposer,
          $$SubscriptionsTableOrderingComposer,
          $$SubscriptionsTableAnnotationComposer,
          $$SubscriptionsTableCreateCompanionBuilder,
          $$SubscriptionsTableUpdateCompanionBuilder,
          (SubscriptionRow, $$SubscriptionsTableReferences),
          SubscriptionRow,
          PrefetchHooks Function({bool sourceDefsRefs})
        > {
  $$SubscriptionsTableTableManager(_$StarDatabase db, $SubscriptionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubscriptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubscriptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubscriptionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<int?> fetchedAt = const Value.absent(),
                Value<String?> raw = const Value.absent(),
              }) => SubscriptionsCompanion(
                id: id,
                kind: kind,
                url: url,
                etag: etag,
                fetchedAt: fetchedAt,
                raw: raw,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String kind,
                Value<String?> url = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<int?> fetchedAt = const Value.absent(),
                Value<String?> raw = const Value.absent(),
              }) => SubscriptionsCompanion.insert(
                id: id,
                kind: kind,
                url: url,
                etag: etag,
                fetchedAt: fetchedAt,
                raw: raw,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SubscriptionsTable, SubscriptionRow>(table),
                  $$SubscriptionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sourceDefsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (sourceDefsRefs) db.sourceDefs],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (sourceDefsRefs)
                    await $_getPrefetchedData<
                      SubscriptionRow,
                      $SubscriptionsTable,
                      SourceDefRow
                    >(
                      currentTable: table,
                      referencedTable: $$SubscriptionsTableReferences
                          ._sourceDefsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SubscriptionsTableReferences(
                            db,
                            table,
                            p0,
                          ).sourceDefsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.subId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SubscriptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$StarDatabase,
      $SubscriptionsTable,
      SubscriptionRow,
      $$SubscriptionsTableFilterComposer,
      $$SubscriptionsTableOrderingComposer,
      $$SubscriptionsTableAnnotationComposer,
      $$SubscriptionsTableCreateCompanionBuilder,
      $$SubscriptionsTableUpdateCompanionBuilder,
      (SubscriptionRow, $$SubscriptionsTableReferences),
      SubscriptionRow,
      PrefetchHooks Function({bool sourceDefsRefs})
    >;
typedef $$SourceDefsTableCreateCompanionBuilder = SourceDefsCompanion Function({
  required String key,
  Value<int?> subId,
  required String name,
  required String kind,
  Value<String> cmsVariant,
  Value<String?> endpoint,
  Value<String?> extRaw,
  Value<String?> extUrl,
  Value<String?> sourceUrl,
  Value<String?> jarRef,
  Value<bool> capsSearchable,
  Value<bool> capsQuickSearch,
  Value<bool> capsFilterable,
  Value<bool> capsChangeable,
  Value<String?> headers,
  Value<int?> timeoutSec,
  Value<String?> unsupportedReason,
  Value<bool> enabled,
  Value<int> sort,
  Value<String?> groupId,
  Value<int> rowid,
});
typedef $$SourceDefsTableUpdateCompanionBuilder = SourceDefsCompanion Function({
  Value<String> key,
  Value<int?> subId,
  Value<String> name,
  Value<String> kind,
  Value<String> cmsVariant,
  Value<String?> endpoint,
  Value<String?> extRaw,
  Value<String?> extUrl,
  Value<String?> sourceUrl,
  Value<String?> jarRef,
  Value<bool> capsSearchable,
  Value<bool> capsQuickSearch,
  Value<bool> capsFilterable,
  Value<bool> capsChangeable,
  Value<String?> headers,
  Value<int?> timeoutSec,
  Value<String?> unsupportedReason,
  Value<bool> enabled,
  Value<int> sort,
  Value<String?> groupId,
  Value<int> rowid,
});

final class $$SourceDefsTableReferences
    extends BaseReferences<_$StarDatabase, $SourceDefsTable, SourceDefRow> {
  $$SourceDefsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SubscriptionsTable _subIdTable(_$StarDatabase db) =>
      db.subscriptions.createAlias('source_defs__sub_id__subscriptions__id');

  $$SubscriptionsTableProcessedTableManager? get subId {
    final $_column = $_itemColumn<int>('sub_id');
    if ($_column == null) return null;
    final manager = $$SubscriptionsTableTableManager(
      $_db,
      $_db.subscriptions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_subIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$HealthRecordsTable, List<HealthRecordRow>>
  _healthRecordsRefsTable(_$StarDatabase db) => MultiTypedResultKey.fromTable(
    db.healthRecords,
    aliasName: 'source_defs__key__health_records__source_key',
  );

  $$HealthRecordsTableProcessedTableManager get healthRecordsRefs {
    final manager = $$HealthRecordsTableTableManager(
      $_db,
      $_db.healthRecords,
    ).filter((f) => f.sourceKey.key.sqlEquals($_itemColumn<String>('key')!));

    final cache = $_typedResult.readTableOrNull(_healthRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SourceDefsTableFilterComposer
    extends Composer<_$StarDatabase, $SourceDefsTable> {
  $$SourceDefsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cmsVariant => $composableBuilder(
    column: $table.cmsVariant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endpoint => $composableBuilder(
    column: $table.endpoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extRaw => $composableBuilder(
    column: $table.extRaw,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extUrl => $composableBuilder(
    column: $table.extUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jarRef => $composableBuilder(
    column: $table.jarRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get capsSearchable => $composableBuilder(
    column: $table.capsSearchable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get capsQuickSearch => $composableBuilder(
    column: $table.capsQuickSearch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get capsFilterable => $composableBuilder(
    column: $table.capsFilterable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get capsChangeable => $composableBuilder(
    column: $table.capsChangeable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get headers => $composableBuilder(
    column: $table.headers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeoutSec => $composableBuilder(
    column: $table.timeoutSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unsupportedReason => $composableBuilder(
    column: $table.unsupportedReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  $$SubscriptionsTableFilterComposer get subId {
    final $$SubscriptionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subId,
      referencedTable: $db.subscriptions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubscriptionsTableFilterComposer(
            $db: $db,
            $table: $db.subscriptions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> healthRecordsRefs(
    Expression<bool> Function($$HealthRecordsTableFilterComposer f) f,
  ) {
    final $$HealthRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.key,
      referencedTable: $db.healthRecords,
      getReferencedColumn: (t) => t.sourceKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HealthRecordsTableFilterComposer(
            $db: $db,
            $table: $db.healthRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SourceDefsTableOrderingComposer
    extends Composer<_$StarDatabase, $SourceDefsTable> {
  $$SourceDefsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cmsVariant => $composableBuilder(
    column: $table.cmsVariant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endpoint => $composableBuilder(
    column: $table.endpoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extRaw => $composableBuilder(
    column: $table.extRaw,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extUrl => $composableBuilder(
    column: $table.extUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jarRef => $composableBuilder(
    column: $table.jarRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get capsSearchable => $composableBuilder(
    column: $table.capsSearchable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get capsQuickSearch => $composableBuilder(
    column: $table.capsQuickSearch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get capsFilterable => $composableBuilder(
    column: $table.capsFilterable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get capsChangeable => $composableBuilder(
    column: $table.capsChangeable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get headers => $composableBuilder(
    column: $table.headers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeoutSec => $composableBuilder(
    column: $table.timeoutSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unsupportedReason => $composableBuilder(
    column: $table.unsupportedReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  $$SubscriptionsTableOrderingComposer get subId {
    final $$SubscriptionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subId,
      referencedTable: $db.subscriptions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubscriptionsTableOrderingComposer(
            $db: $db,
            $table: $db.subscriptions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SourceDefsTableAnnotationComposer
    extends Composer<_$StarDatabase, $SourceDefsTable> {
  $$SourceDefsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get cmsVariant => $composableBuilder(
    column: $table.cmsVariant,
    builder: (column) => column,
  );

  GeneratedColumn<String> get endpoint =>
      $composableBuilder(column: $table.endpoint, builder: (column) => column);

  GeneratedColumn<String> get extRaw =>
      $composableBuilder(column: $table.extRaw, builder: (column) => column);

  GeneratedColumn<String> get extUrl =>
      $composableBuilder(column: $table.extUrl, builder: (column) => column);

  GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);

  GeneratedColumn<String> get jarRef =>
      $composableBuilder(column: $table.jarRef, builder: (column) => column);

  GeneratedColumn<bool> get capsSearchable => $composableBuilder(
    column: $table.capsSearchable,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get capsQuickSearch => $composableBuilder(
    column: $table.capsQuickSearch,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get capsFilterable => $composableBuilder(
    column: $table.capsFilterable,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get capsChangeable => $composableBuilder(
    column: $table.capsChangeable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get headers =>
      $composableBuilder(column: $table.headers, builder: (column) => column);

  GeneratedColumn<int> get timeoutSec => $composableBuilder(
    column: $table.timeoutSec,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unsupportedReason => $composableBuilder(
    column: $table.unsupportedReason,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get sort =>
      $composableBuilder(column: $table.sort, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  $$SubscriptionsTableAnnotationComposer get subId {
    final $$SubscriptionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subId,
      referencedTable: $db.subscriptions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubscriptionsTableAnnotationComposer(
            $db: $db,
            $table: $db.subscriptions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> healthRecordsRefs<T extends Object>(
    Expression<T> Function($$HealthRecordsTableAnnotationComposer a) f,
  ) {
    final $$HealthRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.key,
      referencedTable: $db.healthRecords,
      getReferencedColumn: (t) => t.sourceKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HealthRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.healthRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SourceDefsTableTableManager
    extends
        RootTableManager<
          _$StarDatabase,
          $SourceDefsTable,
          SourceDefRow,
          $$SourceDefsTableFilterComposer,
          $$SourceDefsTableOrderingComposer,
          $$SourceDefsTableAnnotationComposer,
          $$SourceDefsTableCreateCompanionBuilder,
          $$SourceDefsTableUpdateCompanionBuilder,
          (SourceDefRow, $$SourceDefsTableReferences),
          SourceDefRow,
          PrefetchHooks Function({bool subId, bool healthRecordsRefs})
        > {
  $$SourceDefsTableTableManager(_$StarDatabase db, $SourceDefsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SourceDefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SourceDefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SourceDefsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<int?> subId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> cmsVariant = const Value.absent(),
                Value<String?> endpoint = const Value.absent(),
                Value<String?> extRaw = const Value.absent(),
                Value<String?> extUrl = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
                Value<String?> jarRef = const Value.absent(),
                Value<bool> capsSearchable = const Value.absent(),
                Value<bool> capsQuickSearch = const Value.absent(),
                Value<bool> capsFilterable = const Value.absent(),
                Value<bool> capsChangeable = const Value.absent(),
                Value<String?> headers = const Value.absent(),
                Value<int?> timeoutSec = const Value.absent(),
                Value<String?> unsupportedReason = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> sort = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SourceDefsCompanion(
                key: key,
                subId: subId,
                name: name,
                kind: kind,
                cmsVariant: cmsVariant,
                endpoint: endpoint,
                extRaw: extRaw,
                extUrl: extUrl,
                sourceUrl: sourceUrl,
                jarRef: jarRef,
                capsSearchable: capsSearchable,
                capsQuickSearch: capsQuickSearch,
                capsFilterable: capsFilterable,
                capsChangeable: capsChangeable,
                headers: headers,
                timeoutSec: timeoutSec,
                unsupportedReason: unsupportedReason,
                enabled: enabled,
                sort: sort,
                groupId: groupId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                Value<int?> subId = const Value.absent(),
                required String name,
                required String kind,
                Value<String> cmsVariant = const Value.absent(),
                Value<String?> endpoint = const Value.absent(),
                Value<String?> extRaw = const Value.absent(),
                Value<String?> extUrl = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
                Value<String?> jarRef = const Value.absent(),
                Value<bool> capsSearchable = const Value.absent(),
                Value<bool> capsQuickSearch = const Value.absent(),
                Value<bool> capsFilterable = const Value.absent(),
                Value<bool> capsChangeable = const Value.absent(),
                Value<String?> headers = const Value.absent(),
                Value<int?> timeoutSec = const Value.absent(),
                Value<String?> unsupportedReason = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> sort = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SourceDefsCompanion.insert(
                key: key,
                subId: subId,
                name: name,
                kind: kind,
                cmsVariant: cmsVariant,
                endpoint: endpoint,
                extRaw: extRaw,
                extUrl: extUrl,
                sourceUrl: sourceUrl,
                jarRef: jarRef,
                capsSearchable: capsSearchable,
                capsQuickSearch: capsQuickSearch,
                capsFilterable: capsFilterable,
                capsChangeable: capsChangeable,
                headers: headers,
                timeoutSec: timeoutSec,
                unsupportedReason: unsupportedReason,
                enabled: enabled,
                sort: sort,
                groupId: groupId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SourceDefsTable, SourceDefRow>(table),
                  $$SourceDefsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({subId = false, healthRecordsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (healthRecordsRefs) db.healthRecords,
              ],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (subId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.subId,
                        referencedTable: $$SourceDefsTableReferences
                            ._subIdTable(db),
                        referencedColumn: $$SourceDefsTableReferences
                            ._subIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (healthRecordsRefs)
                    await $_getPrefetchedData<
                      SourceDefRow,
                      $SourceDefsTable,
                      HealthRecordRow
                    >(
                      currentTable: table,
                      referencedTable: $$SourceDefsTableReferences
                          ._healthRecordsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SourceDefsTableReferences(
                            db,
                            table,
                            p0,
                          ).healthRecordsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sourceKey == item.key),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SourceDefsTableProcessedTableManager =
    ProcessedTableManager<
      _$StarDatabase,
      $SourceDefsTable,
      SourceDefRow,
      $$SourceDefsTableFilterComposer,
      $$SourceDefsTableOrderingComposer,
      $$SourceDefsTableAnnotationComposer,
      $$SourceDefsTableCreateCompanionBuilder,
      $$SourceDefsTableUpdateCompanionBuilder,
      (SourceDefRow, $$SourceDefsTableReferences),
      SourceDefRow,
      PrefetchHooks Function({bool subId, bool healthRecordsRefs})
    >;
typedef $$WorkSnapshotsTableCreateCompanionBuilder =
    WorkSnapshotsCompanion Function({
      required String workKey,
      required String sourceKey,
      required String title,
      Value<String?> posterPath,
      Value<String?> remarks,
      Value<String?> year,
      Value<String?> area,
      Value<String?> genre,
      Value<String?> score,
      Value<String?> raw,
      Value<int> rowid,
    });
typedef $$WorkSnapshotsTableUpdateCompanionBuilder =
    WorkSnapshotsCompanion Function({
      Value<String> workKey,
      Value<String> sourceKey,
      Value<String> title,
      Value<String?> posterPath,
      Value<String?> remarks,
      Value<String?> year,
      Value<String?> area,
      Value<String?> genre,
      Value<String?> score,
      Value<String?> raw,
      Value<int> rowid,
    });

final class $$WorkSnapshotsTableReferences
    extends
        BaseReferences<_$StarDatabase, $WorkSnapshotsTable, WorkSnapshotRow> {
  $$WorkSnapshotsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$PlayRecordsTable, List<PlayRecordRow>>
  _playRecordsRefsTable(_$StarDatabase db) => MultiTypedResultKey.fromTable(
    db.playRecords,
    aliasName: 'work_snapshots__work_key__play_records__work_key',
  );

  $$PlayRecordsTableProcessedTableManager get playRecordsRefs {
    final manager = $$PlayRecordsTableTableManager($_db, $_db.playRecords)
        .filter(
          (f) => f.workKey.workKey.sqlEquals($_itemColumn<String>('work_key')!),
        );

    final cache = $_typedResult.readTableOrNull(_playRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FavoritesTable, List<FavoriteRow>>
  _favoritesRefsTable(_$StarDatabase db) => MultiTypedResultKey.fromTable(
    db.favorites,
    aliasName: 'work_snapshots__work_key__favorites__work_key',
  );

  $$FavoritesTableProcessedTableManager get favoritesRefs {
    final manager = $$FavoritesTableTableManager($_db, $_db.favorites).filter(
      (f) => f.workKey.workKey.sqlEquals($_itemColumn<String>('work_key')!),
    );

    final cache = $_typedResult.readTableOrNull(_favoritesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorkSnapshotsTableFilterComposer
    extends Composer<_$StarDatabase, $WorkSnapshotsTable> {
  $$WorkSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get workKey => $composableBuilder(
    column: $table.workKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get area => $composableBuilder(
    column: $table.area,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get raw => $composableBuilder(
    column: $table.raw,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> playRecordsRefs(
    Expression<bool> Function($$PlayRecordsTableFilterComposer f) f,
  ) {
    final $$PlayRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workKey,
      referencedTable: $db.playRecords,
      getReferencedColumn: (t) => t.workKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayRecordsTableFilterComposer(
            $db: $db,
            $table: $db.playRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> favoritesRefs(
    Expression<bool> Function($$FavoritesTableFilterComposer f) f,
  ) {
    final $$FavoritesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workKey,
      referencedTable: $db.favorites,
      getReferencedColumn: (t) => t.workKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoritesTableFilterComposer(
            $db: $db,
            $table: $db.favorites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkSnapshotsTableOrderingComposer
    extends Composer<_$StarDatabase, $WorkSnapshotsTable> {
  $$WorkSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get workKey => $composableBuilder(
    column: $table.workKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get area => $composableBuilder(
    column: $table.area,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get raw => $composableBuilder(
    column: $table.raw,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkSnapshotsTableAnnotationComposer
    extends Composer<_$StarDatabase, $WorkSnapshotsTable> {
  $$WorkSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get workKey =>
      $composableBuilder(column: $table.workKey, builder: (column) => column);

  GeneratedColumn<String> get sourceKey =>
      $composableBuilder(column: $table.sourceKey, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remarks =>
      $composableBuilder(column: $table.remarks, builder: (column) => column);

  GeneratedColumn<String> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get area =>
      $composableBuilder(column: $table.area, builder: (column) => column);

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<String> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<String> get raw =>
      $composableBuilder(column: $table.raw, builder: (column) => column);

  Expression<T> playRecordsRefs<T extends Object>(
    Expression<T> Function($$PlayRecordsTableAnnotationComposer a) f,
  ) {
    final $$PlayRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workKey,
      referencedTable: $db.playRecords,
      getReferencedColumn: (t) => t.workKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.playRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> favoritesRefs<T extends Object>(
    Expression<T> Function($$FavoritesTableAnnotationComposer a) f,
  ) {
    final $$FavoritesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workKey,
      referencedTable: $db.favorites,
      getReferencedColumn: (t) => t.workKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoritesTableAnnotationComposer(
            $db: $db,
            $table: $db.favorites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkSnapshotsTableTableManager
    extends
        RootTableManager<
          _$StarDatabase,
          $WorkSnapshotsTable,
          WorkSnapshotRow,
          $$WorkSnapshotsTableFilterComposer,
          $$WorkSnapshotsTableOrderingComposer,
          $$WorkSnapshotsTableAnnotationComposer,
          $$WorkSnapshotsTableCreateCompanionBuilder,
          $$WorkSnapshotsTableUpdateCompanionBuilder,
          (WorkSnapshotRow, $$WorkSnapshotsTableReferences),
          WorkSnapshotRow,
          PrefetchHooks Function({bool playRecordsRefs, bool favoritesRefs})
        > {
  $$WorkSnapshotsTableTableManager(_$StarDatabase db, $WorkSnapshotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> workKey = const Value.absent(),
                Value<String> sourceKey = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> posterPath = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                Value<String?> year = const Value.absent(),
                Value<String?> area = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<String?> score = const Value.absent(),
                Value<String?> raw = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkSnapshotsCompanion(
                workKey: workKey,
                sourceKey: sourceKey,
                title: title,
                posterPath: posterPath,
                remarks: remarks,
                year: year,
                area: area,
                genre: genre,
                score: score,
                raw: raw,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String workKey,
                required String sourceKey,
                required String title,
                Value<String?> posterPath = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                Value<String?> year = const Value.absent(),
                Value<String?> area = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<String?> score = const Value.absent(),
                Value<String?> raw = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkSnapshotsCompanion.insert(
                workKey: workKey,
                sourceKey: sourceKey,
                title: title,
                posterPath: posterPath,
                remarks: remarks,
                year: year,
                area: area,
                genre: genre,
                score: score,
                raw: raw,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkSnapshotsTable, WorkSnapshotRow>(table),
                  $$WorkSnapshotsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({playRecordsRefs = false, favoritesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (playRecordsRefs) db.playRecords,
                    if (favoritesRefs) db.favorites,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (playRecordsRefs)
                        await $_getPrefetchedData<
                          WorkSnapshotRow,
                          $WorkSnapshotsTable,
                          PlayRecordRow
                        >(
                          currentTable: table,
                          referencedTable: $$WorkSnapshotsTableReferences
                              ._playRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkSnapshotsTableReferences(
                                db,
                                table,
                                p0,
                              ).playRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workKey == item.workKey,
                              ),
                          typedResults: items,
                        ),
                      if (favoritesRefs)
                        await $_getPrefetchedData<
                          WorkSnapshotRow,
                          $WorkSnapshotsTable,
                          FavoriteRow
                        >(
                          currentTable: table,
                          referencedTable: $$WorkSnapshotsTableReferences
                              ._favoritesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkSnapshotsTableReferences(
                                db,
                                table,
                                p0,
                              ).favoritesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workKey == item.workKey,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WorkSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$StarDatabase,
      $WorkSnapshotsTable,
      WorkSnapshotRow,
      $$WorkSnapshotsTableFilterComposer,
      $$WorkSnapshotsTableOrderingComposer,
      $$WorkSnapshotsTableAnnotationComposer,
      $$WorkSnapshotsTableCreateCompanionBuilder,
      $$WorkSnapshotsTableUpdateCompanionBuilder,
      (WorkSnapshotRow, $$WorkSnapshotsTableReferences),
      WorkSnapshotRow,
      PrefetchHooks Function({bool playRecordsRefs, bool favoritesRefs})
    >;
typedef $$PlayRecordsTableCreateCompanionBuilder =
    PlayRecordsCompanion Function({
      required String workKey,
      required String sourceKey,
      required int episodeIndex,
      Value<String?> lineId,
      Value<int> positionSec,
      Value<int> durationSec,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$PlayRecordsTableUpdateCompanionBuilder =
    PlayRecordsCompanion Function({
      Value<String> workKey,
      Value<String> sourceKey,
      Value<int> episodeIndex,
      Value<String?> lineId,
      Value<int> positionSec,
      Value<int> durationSec,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$PlayRecordsTableReferences
    extends BaseReferences<_$StarDatabase, $PlayRecordsTable, PlayRecordRow> {
  $$PlayRecordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkSnapshotsTable _workKeyTable(_$StarDatabase db) => db
      .workSnapshots
      .createAlias('play_records__work_key__work_snapshots__work_key');

  $$WorkSnapshotsTableProcessedTableManager get workKey {
    final $_column = $_itemColumn<String>('work_key')!;

    final manager = $$WorkSnapshotsTableTableManager(
      $_db,
      $_db.workSnapshots,
    ).filter((f) => f.workKey.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workKeyTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlayRecordsTableFilterComposer
    extends Composer<_$StarDatabase, $PlayRecordsTable> {
  $$PlayRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get episodeIndex => $composableBuilder(
    column: $table.episodeIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lineId => $composableBuilder(
    column: $table.lineId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionSec => $composableBuilder(
    column: $table.positionSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkSnapshotsTableFilterComposer get workKey {
    final $$WorkSnapshotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workKey,
      referencedTable: $db.workSnapshots,
      getReferencedColumn: (t) => t.workKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkSnapshotsTableFilterComposer(
            $db: $db,
            $table: $db.workSnapshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlayRecordsTableOrderingComposer
    extends Composer<_$StarDatabase, $PlayRecordsTable> {
  $$PlayRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get episodeIndex => $composableBuilder(
    column: $table.episodeIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lineId => $composableBuilder(
    column: $table.lineId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionSec => $composableBuilder(
    column: $table.positionSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkSnapshotsTableOrderingComposer get workKey {
    final $$WorkSnapshotsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workKey,
      referencedTable: $db.workSnapshots,
      getReferencedColumn: (t) => t.workKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkSnapshotsTableOrderingComposer(
            $db: $db,
            $table: $db.workSnapshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlayRecordsTableAnnotationComposer
    extends Composer<_$StarDatabase, $PlayRecordsTable> {
  $$PlayRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sourceKey =>
      $composableBuilder(column: $table.sourceKey, builder: (column) => column);

  GeneratedColumn<int> get episodeIndex => $composableBuilder(
    column: $table.episodeIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lineId =>
      $composableBuilder(column: $table.lineId, builder: (column) => column);

  GeneratedColumn<int> get positionSec => $composableBuilder(
    column: $table.positionSec,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$WorkSnapshotsTableAnnotationComposer get workKey {
    final $$WorkSnapshotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workKey,
      referencedTable: $db.workSnapshots,
      getReferencedColumn: (t) => t.workKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkSnapshotsTableAnnotationComposer(
            $db: $db,
            $table: $db.workSnapshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlayRecordsTableTableManager
    extends
        RootTableManager<
          _$StarDatabase,
          $PlayRecordsTable,
          PlayRecordRow,
          $$PlayRecordsTableFilterComposer,
          $$PlayRecordsTableOrderingComposer,
          $$PlayRecordsTableAnnotationComposer,
          $$PlayRecordsTableCreateCompanionBuilder,
          $$PlayRecordsTableUpdateCompanionBuilder,
          (PlayRecordRow, $$PlayRecordsTableReferences),
          PlayRecordRow,
          PrefetchHooks Function({bool workKey})
        > {
  $$PlayRecordsTableTableManager(_$StarDatabase db, $PlayRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> workKey = const Value.absent(),
                Value<String> sourceKey = const Value.absent(),
                Value<int> episodeIndex = const Value.absent(),
                Value<String?> lineId = const Value.absent(),
                Value<int> positionSec = const Value.absent(),
                Value<int> durationSec = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlayRecordsCompanion(
                workKey: workKey,
                sourceKey: sourceKey,
                episodeIndex: episodeIndex,
                lineId: lineId,
                positionSec: positionSec,
                durationSec: durationSec,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String workKey,
                required String sourceKey,
                required int episodeIndex,
                Value<String?> lineId = const Value.absent(),
                Value<int> positionSec = const Value.absent(),
                Value<int> durationSec = const Value.absent(),
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PlayRecordsCompanion.insert(
                workKey: workKey,
                sourceKey: sourceKey,
                episodeIndex: episodeIndex,
                lineId: lineId,
                positionSec: positionSec,
                durationSec: durationSec,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlayRecordsTable, PlayRecordRow>(table),
                  $$PlayRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workKey = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workKey) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.workKey,
                        referencedTable: $$PlayRecordsTableReferences
                            ._workKeyTable(db),
                        referencedColumn: $$PlayRecordsTableReferences
                            ._workKeyTable(db)
                            .workKey,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlayRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$StarDatabase,
      $PlayRecordsTable,
      PlayRecordRow,
      $$PlayRecordsTableFilterComposer,
      $$PlayRecordsTableOrderingComposer,
      $$PlayRecordsTableAnnotationComposer,
      $$PlayRecordsTableCreateCompanionBuilder,
      $$PlayRecordsTableUpdateCompanionBuilder,
      (PlayRecordRow, $$PlayRecordsTableReferences),
      PlayRecordRow,
      PrefetchHooks Function({bool workKey})
    >;
typedef $$FavoriteFoldersTableCreateCompanionBuilder =
    FavoriteFoldersCompanion Function({
      Value<int> id,
      required String name,
      Value<int> sort,
    });
typedef $$FavoriteFoldersTableUpdateCompanionBuilder =
    FavoriteFoldersCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> sort,
    });

final class $$FavoriteFoldersTableReferences
    extends
        BaseReferences<
          _$StarDatabase,
          $FavoriteFoldersTable,
          FavoriteFolderRow
        > {
  $$FavoriteFoldersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$FavoritesTable, List<FavoriteRow>>
  _favoritesRefsTable(_$StarDatabase db) => MultiTypedResultKey.fromTable(
    db.favorites,
    aliasName: 'favorite_folders__id__favorites__folder_id',
  );

  $$FavoritesTableProcessedTableManager get favoritesRefs {
    final manager = $$FavoritesTableTableManager(
      $_db,
      $_db.favorites,
    ).filter((f) => f.folderId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_favoritesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FavoriteFoldersTableFilterComposer
    extends Composer<_$StarDatabase, $FavoriteFoldersTable> {
  $$FavoriteFoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> favoritesRefs(
    Expression<bool> Function($$FavoritesTableFilterComposer f) f,
  ) {
    final $$FavoritesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.favorites,
      getReferencedColumn: (t) => t.folderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoritesTableFilterComposer(
            $db: $db,
            $table: $db.favorites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FavoriteFoldersTableOrderingComposer
    extends Composer<_$StarDatabase, $FavoriteFoldersTable> {
  $$FavoriteFoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FavoriteFoldersTableAnnotationComposer
    extends Composer<_$StarDatabase, $FavoriteFoldersTable> {
  $$FavoriteFoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sort =>
      $composableBuilder(column: $table.sort, builder: (column) => column);

  Expression<T> favoritesRefs<T extends Object>(
    Expression<T> Function($$FavoritesTableAnnotationComposer a) f,
  ) {
    final $$FavoritesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.favorites,
      getReferencedColumn: (t) => t.folderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoritesTableAnnotationComposer(
            $db: $db,
            $table: $db.favorites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FavoriteFoldersTableTableManager
    extends
        RootTableManager<
          _$StarDatabase,
          $FavoriteFoldersTable,
          FavoriteFolderRow,
          $$FavoriteFoldersTableFilterComposer,
          $$FavoriteFoldersTableOrderingComposer,
          $$FavoriteFoldersTableAnnotationComposer,
          $$FavoriteFoldersTableCreateCompanionBuilder,
          $$FavoriteFoldersTableUpdateCompanionBuilder,
          (FavoriteFolderRow, $$FavoriteFoldersTableReferences),
          FavoriteFolderRow,
          PrefetchHooks Function({bool favoritesRefs})
        > {
  $$FavoriteFoldersTableTableManager(
    _$StarDatabase db,
    $FavoriteFoldersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoriteFoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoriteFoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoriteFoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> sort = const Value.absent(),
          }) => FavoriteFoldersCompanion(id: id, name: name, sort: sort),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<int> sort = const Value.absent(),
          }) => FavoriteFoldersCompanion.insert(id: id, name: name, sort: sort),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FavoriteFoldersTable, FavoriteFolderRow>(table),
                  $$FavoriteFoldersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({favoritesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (favoritesRefs) db.favorites],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (favoritesRefs)
                    await $_getPrefetchedData<
                      FavoriteFolderRow,
                      $FavoriteFoldersTable,
                      FavoriteRow
                    >(
                      currentTable: table,
                      referencedTable: $$FavoriteFoldersTableReferences
                          ._favoritesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$FavoriteFoldersTableReferences(
                            db,
                            table,
                            p0,
                          ).favoritesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.folderId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$FavoriteFoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$StarDatabase,
      $FavoriteFoldersTable,
      FavoriteFolderRow,
      $$FavoriteFoldersTableFilterComposer,
      $$FavoriteFoldersTableOrderingComposer,
      $$FavoriteFoldersTableAnnotationComposer,
      $$FavoriteFoldersTableCreateCompanionBuilder,
      $$FavoriteFoldersTableUpdateCompanionBuilder,
      (FavoriteFolderRow, $$FavoriteFoldersTableReferences),
      FavoriteFolderRow,
      PrefetchHooks Function({bool favoritesRefs})
    >;
typedef $$FavoritesTableCreateCompanionBuilder = FavoritesCompanion Function({
  required String workKey,
  Value<int?> folderId,
  required int createdAt,
  Value<int> rowid,
});
typedef $$FavoritesTableUpdateCompanionBuilder = FavoritesCompanion Function({
  Value<String> workKey,
  Value<int?> folderId,
  Value<int> createdAt,
  Value<int> rowid,
});

final class $$FavoritesTableReferences
    extends BaseReferences<_$StarDatabase, $FavoritesTable, FavoriteRow> {
  $$FavoritesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkSnapshotsTable _workKeyTable(_$StarDatabase db) => db
      .workSnapshots
      .createAlias('favorites__work_key__work_snapshots__work_key');

  $$WorkSnapshotsTableProcessedTableManager get workKey {
    final $_column = $_itemColumn<String>('work_key')!;

    final manager = $$WorkSnapshotsTableTableManager(
      $_db,
      $_db.workSnapshots,
    ).filter((f) => f.workKey.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workKeyTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $FavoriteFoldersTable _folderIdTable(_$StarDatabase db) => db
      .favoriteFolders
      .createAlias('favorites__folder_id__favorite_folders__id');

  $$FavoriteFoldersTableProcessedTableManager? get folderId {
    final $_column = $_itemColumn<int>('folder_id');
    if ($_column == null) return null;
    final manager = $$FavoriteFoldersTableTableManager(
      $_db,
      $_db.favoriteFolders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_folderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FavoritesTableFilterComposer
    extends Composer<_$StarDatabase, $FavoritesTable> {
  $$FavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkSnapshotsTableFilterComposer get workKey {
    final $$WorkSnapshotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workKey,
      referencedTable: $db.workSnapshots,
      getReferencedColumn: (t) => t.workKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkSnapshotsTableFilterComposer(
            $db: $db,
            $table: $db.workSnapshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FavoriteFoldersTableFilterComposer get folderId {
    final $$FavoriteFoldersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.favoriteFolders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoriteFoldersTableFilterComposer(
            $db: $db,
            $table: $db.favoriteFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoritesTableOrderingComposer
    extends Composer<_$StarDatabase, $FavoritesTable> {
  $$FavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkSnapshotsTableOrderingComposer get workKey {
    final $$WorkSnapshotsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workKey,
      referencedTable: $db.workSnapshots,
      getReferencedColumn: (t) => t.workKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkSnapshotsTableOrderingComposer(
            $db: $db,
            $table: $db.workSnapshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FavoriteFoldersTableOrderingComposer get folderId {
    final $$FavoriteFoldersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.favoriteFolders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoriteFoldersTableOrderingComposer(
            $db: $db,
            $table: $db.favoriteFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoritesTableAnnotationComposer
    extends Composer<_$StarDatabase, $FavoritesTable> {
  $$FavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$WorkSnapshotsTableAnnotationComposer get workKey {
    final $$WorkSnapshotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workKey,
      referencedTable: $db.workSnapshots,
      getReferencedColumn: (t) => t.workKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkSnapshotsTableAnnotationComposer(
            $db: $db,
            $table: $db.workSnapshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FavoriteFoldersTableAnnotationComposer get folderId {
    final $$FavoriteFoldersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.favoriteFolders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoriteFoldersTableAnnotationComposer(
            $db: $db,
            $table: $db.favoriteFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoritesTableTableManager
    extends
        RootTableManager<
          _$StarDatabase,
          $FavoritesTable,
          FavoriteRow,
          $$FavoritesTableFilterComposer,
          $$FavoritesTableOrderingComposer,
          $$FavoritesTableAnnotationComposer,
          $$FavoritesTableCreateCompanionBuilder,
          $$FavoritesTableUpdateCompanionBuilder,
          (FavoriteRow, $$FavoritesTableReferences),
          FavoriteRow,
          PrefetchHooks Function({bool workKey, bool folderId})
        > {
  $$FavoritesTableTableManager(_$StarDatabase db, $FavoritesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> workKey = const Value.absent(),
                Value<int?> folderId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FavoritesCompanion(
                workKey: workKey,
                folderId: folderId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String workKey,
                Value<int?> folderId = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => FavoritesCompanion.insert(
                workKey: workKey,
                folderId: folderId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FavoritesTable, FavoriteRow>(table),
                  $$FavoritesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workKey = false, folderId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workKey) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.workKey,
                        referencedTable: $$FavoritesTableReferences
                            ._workKeyTable(db),
                        referencedColumn: $$FavoritesTableReferences
                            ._workKeyTable(db)
                            .workKey,
                      ) as T;
                    }
                    if (folderId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.folderId,
                        referencedTable: $$FavoritesTableReferences
                            ._folderIdTable(db),
                        referencedColumn: $$FavoritesTableReferences
                            ._folderIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FavoritesTableProcessedTableManager =
    ProcessedTableManager<
      _$StarDatabase,
      $FavoritesTable,
      FavoriteRow,
      $$FavoritesTableFilterComposer,
      $$FavoritesTableOrderingComposer,
      $$FavoritesTableAnnotationComposer,
      $$FavoritesTableCreateCompanionBuilder,
      $$FavoritesTableUpdateCompanionBuilder,
      (FavoriteRow, $$FavoritesTableReferences),
      FavoriteRow,
      PrefetchHooks Function({bool workKey, bool folderId})
    >;
typedef $$LiveChannelsTableCreateCompanionBuilder =
    LiveChannelsCompanion Function({
      Value<int> id,
      required String groupId,
      required String name,
      required String url,
      Value<String?> logo,
      Value<String?> epgId,
      Value<int?> tuneNo,
      Value<int> sort,
    });
typedef $$LiveChannelsTableUpdateCompanionBuilder =
    LiveChannelsCompanion Function({
      Value<int> id,
      Value<String> groupId,
      Value<String> name,
      Value<String> url,
      Value<String?> logo,
      Value<String?> epgId,
      Value<int?> tuneNo,
      Value<int> sort,
    });

class $$LiveChannelsTableFilterComposer
    extends Composer<_$StarDatabase, $LiveChannelsTable> {
  $$LiveChannelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logo => $composableBuilder(
    column: $table.logo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get epgId => $composableBuilder(
    column: $table.epgId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tuneNo => $composableBuilder(
    column: $table.tuneNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LiveChannelsTableOrderingComposer
    extends Composer<_$StarDatabase, $LiveChannelsTable> {
  $$LiveChannelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logo => $composableBuilder(
    column: $table.logo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get epgId => $composableBuilder(
    column: $table.epgId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tuneNo => $composableBuilder(
    column: $table.tuneNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LiveChannelsTableAnnotationComposer
    extends Composer<_$StarDatabase, $LiveChannelsTable> {
  $$LiveChannelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get logo =>
      $composableBuilder(column: $table.logo, builder: (column) => column);

  GeneratedColumn<String> get epgId =>
      $composableBuilder(column: $table.epgId, builder: (column) => column);

  GeneratedColumn<int> get tuneNo =>
      $composableBuilder(column: $table.tuneNo, builder: (column) => column);

  GeneratedColumn<int> get sort =>
      $composableBuilder(column: $table.sort, builder: (column) => column);
}

class $$LiveChannelsTableTableManager
    extends
        RootTableManager<
          _$StarDatabase,
          $LiveChannelsTable,
          LiveChannelRow,
          $$LiveChannelsTableFilterComposer,
          $$LiveChannelsTableOrderingComposer,
          $$LiveChannelsTableAnnotationComposer,
          $$LiveChannelsTableCreateCompanionBuilder,
          $$LiveChannelsTableUpdateCompanionBuilder,
          (
            LiveChannelRow,
            BaseReferences<_$StarDatabase, $LiveChannelsTable, LiveChannelRow>,
          ),
          LiveChannelRow,
          PrefetchHooks Function()
        > {
  $$LiveChannelsTableTableManager(_$StarDatabase db, $LiveChannelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LiveChannelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LiveChannelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LiveChannelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String?> logo = const Value.absent(),
                Value<String?> epgId = const Value.absent(),
                Value<int?> tuneNo = const Value.absent(),
                Value<int> sort = const Value.absent(),
              }) => LiveChannelsCompanion(
                id: id,
                groupId: groupId,
                name: name,
                url: url,
                logo: logo,
                epgId: epgId,
                tuneNo: tuneNo,
                sort: sort,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String groupId,
                required String name,
                required String url,
                Value<String?> logo = const Value.absent(),
                Value<String?> epgId = const Value.absent(),
                Value<int?> tuneNo = const Value.absent(),
                Value<int> sort = const Value.absent(),
              }) => LiveChannelsCompanion.insert(
                id: id,
                groupId: groupId,
                name: name,
                url: url,
                logo: logo,
                epgId: epgId,
                tuneNo: tuneNo,
                sort: sort,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LiveChannelsTable, LiveChannelRow>(table),
                  BaseReferences<
                    _$StarDatabase,
                    $LiveChannelsTable,
                    LiveChannelRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LiveChannelsTableProcessedTableManager =
    ProcessedTableManager<
      _$StarDatabase,
      $LiveChannelsTable,
      LiveChannelRow,
      $$LiveChannelsTableFilterComposer,
      $$LiveChannelsTableOrderingComposer,
      $$LiveChannelsTableAnnotationComposer,
      $$LiveChannelsTableCreateCompanionBuilder,
      $$LiveChannelsTableUpdateCompanionBuilder,
      (
        LiveChannelRow,
        BaseReferences<_$StarDatabase, $LiveChannelsTable, LiveChannelRow>,
      ),
      LiveChannelRow,
      PrefetchHooks Function()
    >;
typedef $$HealthRecordsTableCreateCompanionBuilder =
    HealthRecordsCompanion Function({
      Value<int> id,
      required String sourceKey,
      required int ts,
      Value<int?> latencyMs,
      required bool ok,
      Value<String?> failStage,
    });
typedef $$HealthRecordsTableUpdateCompanionBuilder =
    HealthRecordsCompanion Function({
      Value<int> id,
      Value<String> sourceKey,
      Value<int> ts,
      Value<int?> latencyMs,
      Value<bool> ok,
      Value<String?> failStage,
    });

final class $$HealthRecordsTableReferences
    extends
        BaseReferences<_$StarDatabase, $HealthRecordsTable, HealthRecordRow> {
  $$HealthRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SourceDefsTable _sourceKeyTable(_$StarDatabase db) =>
      db.sourceDefs.createAlias('health_records__source_key__source_defs__key');

  $$SourceDefsTableProcessedTableManager get sourceKey {
    final $_column = $_itemColumn<String>('source_key')!;

    final manager = $$SourceDefsTableTableManager(
      $_db,
      $_db.sourceDefs,
    ).filter((f) => f.key.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceKeyTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HealthRecordsTableFilterComposer
    extends Composer<_$StarDatabase, $HealthRecordsTable> {
  $$HealthRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get latencyMs => $composableBuilder(
    column: $table.latencyMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get ok => $composableBuilder(
    column: $table.ok,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get failStage => $composableBuilder(
    column: $table.failStage,
    builder: (column) => ColumnFilters(column),
  );

  $$SourceDefsTableFilterComposer get sourceKey {
    final $$SourceDefsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceKey,
      referencedTable: $db.sourceDefs,
      getReferencedColumn: (t) => t.key,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourceDefsTableFilterComposer(
            $db: $db,
            $table: $db.sourceDefs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HealthRecordsTableOrderingComposer
    extends Composer<_$StarDatabase, $HealthRecordsTable> {
  $$HealthRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get latencyMs => $composableBuilder(
    column: $table.latencyMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get ok => $composableBuilder(
    column: $table.ok,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get failStage => $composableBuilder(
    column: $table.failStage,
    builder: (column) => ColumnOrderings(column),
  );

  $$SourceDefsTableOrderingComposer get sourceKey {
    final $$SourceDefsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceKey,
      referencedTable: $db.sourceDefs,
      getReferencedColumn: (t) => t.key,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourceDefsTableOrderingComposer(
            $db: $db,
            $table: $db.sourceDefs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HealthRecordsTableAnnotationComposer
    extends Composer<_$StarDatabase, $HealthRecordsTable> {
  $$HealthRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<int> get latencyMs =>
      $composableBuilder(column: $table.latencyMs, builder: (column) => column);

  GeneratedColumn<bool> get ok =>
      $composableBuilder(column: $table.ok, builder: (column) => column);

  GeneratedColumn<String> get failStage =>
      $composableBuilder(column: $table.failStage, builder: (column) => column);

  $$SourceDefsTableAnnotationComposer get sourceKey {
    final $$SourceDefsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceKey,
      referencedTable: $db.sourceDefs,
      getReferencedColumn: (t) => t.key,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourceDefsTableAnnotationComposer(
            $db: $db,
            $table: $db.sourceDefs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HealthRecordsTableTableManager
    extends
        RootTableManager<
          _$StarDatabase,
          $HealthRecordsTable,
          HealthRecordRow,
          $$HealthRecordsTableFilterComposer,
          $$HealthRecordsTableOrderingComposer,
          $$HealthRecordsTableAnnotationComposer,
          $$HealthRecordsTableCreateCompanionBuilder,
          $$HealthRecordsTableUpdateCompanionBuilder,
          (HealthRecordRow, $$HealthRecordsTableReferences),
          HealthRecordRow,
          PrefetchHooks Function({bool sourceKey})
        > {
  $$HealthRecordsTableTableManager(_$StarDatabase db, $HealthRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HealthRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HealthRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HealthRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sourceKey = const Value.absent(),
                Value<int> ts = const Value.absent(),
                Value<int?> latencyMs = const Value.absent(),
                Value<bool> ok = const Value.absent(),
                Value<String?> failStage = const Value.absent(),
              }) => HealthRecordsCompanion(
                id: id,
                sourceKey: sourceKey,
                ts: ts,
                latencyMs: latencyMs,
                ok: ok,
                failStage: failStage,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sourceKey,
                required int ts,
                Value<int?> latencyMs = const Value.absent(),
                required bool ok,
                Value<String?> failStage = const Value.absent(),
              }) => HealthRecordsCompanion.insert(
                id: id,
                sourceKey: sourceKey,
                ts: ts,
                latencyMs: latencyMs,
                ok: ok,
                failStage: failStage,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HealthRecordsTable, HealthRecordRow>(table),
                  $$HealthRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sourceKey = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sourceKey) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sourceKey,
                        referencedTable: $$HealthRecordsTableReferences
                            ._sourceKeyTable(db),
                        referencedColumn: $$HealthRecordsTableReferences
                            ._sourceKeyTable(db)
                            .key,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$HealthRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$StarDatabase,
      $HealthRecordsTable,
      HealthRecordRow,
      $$HealthRecordsTableFilterComposer,
      $$HealthRecordsTableOrderingComposer,
      $$HealthRecordsTableAnnotationComposer,
      $$HealthRecordsTableCreateCompanionBuilder,
      $$HealthRecordsTableUpdateCompanionBuilder,
      (HealthRecordRow, $$HealthRecordsTableReferences),
      HealthRecordRow,
      PrefetchHooks Function({bool sourceKey})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$StarDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$StarDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$StarDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$StarDatabase,
          $AppSettingsTable,
          AppSettingRow,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSettingRow,
            BaseReferences<_$StarDatabase, $AppSettingsTable, AppSettingRow>,
          ),
          AppSettingRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$StarDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSettingRow>(table),
                  BaseReferences<
                    _$StarDatabase,
                    $AppSettingsTable,
                    AppSettingRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$StarDatabase,
      $AppSettingsTable,
      AppSettingRow,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSettingRow,
        BaseReferences<_$StarDatabase, $AppSettingsTable, AppSettingRow>,
      ),
      AppSettingRow,
      PrefetchHooks Function()
    >;

class $StarDatabaseManager {
  final _$StarDatabase _db;
  $StarDatabaseManager(this._db);
  $$SubscriptionsTableTableManager get subscriptions =>
      $$SubscriptionsTableTableManager(_db, _db.subscriptions);
  $$SourceDefsTableTableManager get sourceDefs =>
      $$SourceDefsTableTableManager(_db, _db.sourceDefs);
  $$WorkSnapshotsTableTableManager get workSnapshots =>
      $$WorkSnapshotsTableTableManager(_db, _db.workSnapshots);
  $$PlayRecordsTableTableManager get playRecords =>
      $$PlayRecordsTableTableManager(_db, _db.playRecords);
  $$FavoriteFoldersTableTableManager get favoriteFolders =>
      $$FavoriteFoldersTableTableManager(_db, _db.favoriteFolders);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db, _db.favorites);
  $$LiveChannelsTableTableManager get liveChannels =>
      $$LiveChannelsTableTableManager(_db, _db.liveChannels);
  $$HealthRecordsTableTableManager get healthRecords =>
      $$HealthRecordsTableTableManager(_db, _db.healthRecords);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
