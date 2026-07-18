// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database.dart';

// ignore_for_file: type=lint
class $PatientsTable extends Patients with TableInfo<$PatientsTable, Patient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PatientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _abhaIdMeta = const VerificationMeta('abhaId');
  @override
  late final GeneratedColumn<String> abhaId = GeneratedColumn<String>(
      'abha_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _photoPathMeta =
      const VerificationMeta('photoPath');
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
      'photo_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dobMeta = const VerificationMeta('dob');
  @override
  late final GeneratedColumn<DateTime> dob = GeneratedColumn<DateTime>(
      'dob', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
      'gender', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _villageMeta =
      const VerificationMeta('village');
  @override
  late final GeneratedColumn<String> village = GeneratedColumn<String>(
      'village', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isHighRiskMeta =
      const VerificationMeta('isHighRisk');
  @override
  late final GeneratedColumn<bool> isHighRisk = GeneratedColumn<bool>(
      'is_high_risk', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_high_risk" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isPregnantMeta =
      const VerificationMeta('isPregnant');
  @override
  late final GeneratedColumn<bool> isPregnant = GeneratedColumn<bool>(
      'is_pregnant', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_pregnant" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _vaccinationRequiredMeta =
      const VerificationMeta('vaccinationRequired');
  @override
  late final GeneratedColumn<bool> vaccinationRequired = GeneratedColumn<bool>(
      'vaccination_required', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("vaccination_required" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _bloodPressureMeta =
      const VerificationMeta('bloodPressure');
  @override
  late final GeneratedColumn<String> bloodPressure = GeneratedColumn<String>(
      'blood_pressure', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _hemoglobinMeta =
      const VerificationMeta('hemoglobin');
  @override
  late final GeneratedColumn<double> hemoglobin = GeneratedColumn<double>(
      'hemoglobin', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _bloodSugarMeta =
      const VerificationMeta('bloodSugar');
  @override
  late final GeneratedColumn<double> bloodSugar = GeneratedColumn<double>(
      'blood_sugar', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _temperatureMeta =
      const VerificationMeta('temperature');
  @override
  late final GeneratedColumn<double> temperature = GeneratedColumn<double>(
      'temperature', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
      'weight', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _symptomsMeta =
      const VerificationMeta('symptoms');
  @override
  late final GeneratedColumn<String> symptoms = GeneratedColumn<String>(
      'symptoms', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _previousPregnanciesMeta =
      const VerificationMeta('previousPregnancies');
  @override
  late final GeneratedColumn<int> previousPregnancies = GeneratedColumn<int>(
      'previous_pregnancies', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _riskLevelMeta =
      const VerificationMeta('riskLevel');
  @override
  late final GeneratedColumn<String> riskLevel = GeneratedColumn<String>(
      'risk_level', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Low'));
  static const VerificationMeta _confidenceScoreMeta =
      const VerificationMeta('confidenceScore');
  @override
  late final GeneratedColumn<double> confidenceScore = GeneratedColumn<double>(
      'confidence_score', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _reasonsMeta =
      const VerificationMeta('reasons');
  @override
  late final GeneratedColumn<String> reasons = GeneratedColumn<String>(
      'reasons', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _recommendationsMeta =
      const VerificationMeta('recommendations');
  @override
  late final GeneratedColumn<String> recommendations = GeneratedColumn<String>(
      'recommendations', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nextFollowUpMeta =
      const VerificationMeta('nextFollowUp');
  @override
  late final GeneratedColumn<DateTime> nextFollowUp = GeneratedColumn<DateTime>(
      'next_follow_up', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _placeIdMeta =
      const VerificationMeta('placeId');
  @override
  late final GeneratedColumn<String> placeId = GeneratedColumn<String>(
      'place_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _districtMeta =
      const VerificationMeta('district');
  @override
  late final GeneratedColumn<String> district = GeneratedColumn<String>(
      'district', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
      'state', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _countryMeta =
      const VerificationMeta('country');
  @override
  late final GeneratedColumn<String> country = GeneratedColumn<String>(
      'country', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _postalCodeMeta =
      const VerificationMeta('postalCode');
  @override
  late final GeneratedColumn<String> postalCode = GeneratedColumn<String>(
      'postal_code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        abhaId,
        name,
        photoPath,
        dob,
        gender,
        phone,
        village,
        isHighRisk,
        isPregnant,
        vaccinationRequired,
        bloodPressure,
        hemoglobin,
        bloodSugar,
        temperature,
        weight,
        symptoms,
        previousPregnancies,
        riskLevel,
        confidenceScore,
        reasons,
        recommendations,
        nextFollowUp,
        latitude,
        longitude,
        placeId,
        district,
        state,
        country,
        postalCode,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'patients';
  @override
  VerificationContext validateIntegrity(Insertable<Patient> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('abha_id')) {
      context.handle(_abhaIdMeta,
          abhaId.isAcceptableOrUnknown(data['abha_id']!, _abhaIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('photo_path')) {
      context.handle(_photoPathMeta,
          photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta));
    }
    if (data.containsKey('dob')) {
      context.handle(
          _dobMeta, dob.isAcceptableOrUnknown(data['dob']!, _dobMeta));
    } else if (isInserting) {
      context.missing(_dobMeta);
    }
    if (data.containsKey('gender')) {
      context.handle(_genderMeta,
          gender.isAcceptableOrUnknown(data['gender']!, _genderMeta));
    } else if (isInserting) {
      context.missing(_genderMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('village')) {
      context.handle(_villageMeta,
          village.isAcceptableOrUnknown(data['village']!, _villageMeta));
    } else if (isInserting) {
      context.missing(_villageMeta);
    }
    if (data.containsKey('is_high_risk')) {
      context.handle(
          _isHighRiskMeta,
          isHighRisk.isAcceptableOrUnknown(
              data['is_high_risk']!, _isHighRiskMeta));
    }
    if (data.containsKey('is_pregnant')) {
      context.handle(
          _isPregnantMeta,
          isPregnant.isAcceptableOrUnknown(
              data['is_pregnant']!, _isPregnantMeta));
    }
    if (data.containsKey('vaccination_required')) {
      context.handle(
          _vaccinationRequiredMeta,
          vaccinationRequired.isAcceptableOrUnknown(
              data['vaccination_required']!, _vaccinationRequiredMeta));
    }
    if (data.containsKey('blood_pressure')) {
      context.handle(
          _bloodPressureMeta,
          bloodPressure.isAcceptableOrUnknown(
              data['blood_pressure']!, _bloodPressureMeta));
    }
    if (data.containsKey('hemoglobin')) {
      context.handle(
          _hemoglobinMeta,
          hemoglobin.isAcceptableOrUnknown(
              data['hemoglobin']!, _hemoglobinMeta));
    }
    if (data.containsKey('blood_sugar')) {
      context.handle(
          _bloodSugarMeta,
          bloodSugar.isAcceptableOrUnknown(
              data['blood_sugar']!, _bloodSugarMeta));
    }
    if (data.containsKey('temperature')) {
      context.handle(
          _temperatureMeta,
          temperature.isAcceptableOrUnknown(
              data['temperature']!, _temperatureMeta));
    }
    if (data.containsKey('weight')) {
      context.handle(_weightMeta,
          weight.isAcceptableOrUnknown(data['weight']!, _weightMeta));
    }
    if (data.containsKey('symptoms')) {
      context.handle(_symptomsMeta,
          symptoms.isAcceptableOrUnknown(data['symptoms']!, _symptomsMeta));
    }
    if (data.containsKey('previous_pregnancies')) {
      context.handle(
          _previousPregnanciesMeta,
          previousPregnancies.isAcceptableOrUnknown(
              data['previous_pregnancies']!, _previousPregnanciesMeta));
    }
    if (data.containsKey('risk_level')) {
      context.handle(_riskLevelMeta,
          riskLevel.isAcceptableOrUnknown(data['risk_level']!, _riskLevelMeta));
    }
    if (data.containsKey('confidence_score')) {
      context.handle(
          _confidenceScoreMeta,
          confidenceScore.isAcceptableOrUnknown(
              data['confidence_score']!, _confidenceScoreMeta));
    }
    if (data.containsKey('reasons')) {
      context.handle(_reasonsMeta,
          reasons.isAcceptableOrUnknown(data['reasons']!, _reasonsMeta));
    }
    if (data.containsKey('recommendations')) {
      context.handle(
          _recommendationsMeta,
          recommendations.isAcceptableOrUnknown(
              data['recommendations']!, _recommendationsMeta));
    }
    if (data.containsKey('next_follow_up')) {
      context.handle(
          _nextFollowUpMeta,
          nextFollowUp.isAcceptableOrUnknown(
              data['next_follow_up']!, _nextFollowUpMeta));
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    }
    if (data.containsKey('place_id')) {
      context.handle(_placeIdMeta,
          placeId.isAcceptableOrUnknown(data['place_id']!, _placeIdMeta));
    }
    if (data.containsKey('district')) {
      context.handle(_districtMeta,
          district.isAcceptableOrUnknown(data['district']!, _districtMeta));
    }
    if (data.containsKey('state')) {
      context.handle(
          _stateMeta, state.isAcceptableOrUnknown(data['state']!, _stateMeta));
    }
    if (data.containsKey('country')) {
      context.handle(_countryMeta,
          country.isAcceptableOrUnknown(data['country']!, _countryMeta));
    }
    if (data.containsKey('postal_code')) {
      context.handle(
          _postalCodeMeta,
          postalCode.isAcceptableOrUnknown(
              data['postal_code']!, _postalCodeMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Patient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Patient(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      abhaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}abha_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      photoPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_path']),
      dob: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}dob'])!,
      gender: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gender'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone'])!,
      village: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}village'])!,
      isHighRisk: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_high_risk'])!,
      isPregnant: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_pregnant'])!,
      vaccinationRequired: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}vaccination_required'])!,
      bloodPressure: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}blood_pressure']),
      hemoglobin: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}hemoglobin']),
      bloodSugar: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}blood_sugar']),
      temperature: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}temperature']),
      weight: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight']),
      symptoms: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}symptoms']),
      previousPregnancies: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}previous_pregnancies'])!,
      riskLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}risk_level'])!,
      confidenceScore: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}confidence_score'])!,
      reasons: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reasons']),
      recommendations: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recommendations']),
      nextFollowUp: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}next_follow_up']),
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude']),
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude']),
      placeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}place_id']),
      district: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}district']),
      state: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}state']),
      country: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}country']),
      postalCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}postal_code']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $PatientsTable createAlias(String alias) {
    return $PatientsTable(attachedDatabase, alias);
  }
}

class Patient extends DataClass implements Insertable<Patient> {
  final String id;
  final String? abhaId;
  final String name;
  final String? photoPath;
  final DateTime dob;
  final String gender;
  final String phone;
  final String village;
  final bool isHighRisk;
  final bool isPregnant;
  final bool vaccinationRequired;
  final String? bloodPressure;
  final double? hemoglobin;
  final double? bloodSugar;
  final double? temperature;
  final double? weight;
  final String? symptoms;
  final int previousPregnancies;
  final String riskLevel;
  final double confidenceScore;
  final String? reasons;
  final String? recommendations;
  final DateTime? nextFollowUp;
  final double? latitude;
  final double? longitude;
  final String? placeId;
  final String? district;
  final String? state;
  final String? country;
  final String? postalCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Patient(
      {required this.id,
      this.abhaId,
      required this.name,
      this.photoPath,
      required this.dob,
      required this.gender,
      required this.phone,
      required this.village,
      required this.isHighRisk,
      required this.isPregnant,
      required this.vaccinationRequired,
      this.bloodPressure,
      this.hemoglobin,
      this.bloodSugar,
      this.temperature,
      this.weight,
      this.symptoms,
      required this.previousPregnancies,
      required this.riskLevel,
      required this.confidenceScore,
      this.reasons,
      this.recommendations,
      this.nextFollowUp,
      this.latitude,
      this.longitude,
      this.placeId,
      this.district,
      this.state,
      this.country,
      this.postalCode,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || abhaId != null) {
      map['abha_id'] = Variable<String>(abhaId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    map['dob'] = Variable<DateTime>(dob);
    map['gender'] = Variable<String>(gender);
    map['phone'] = Variable<String>(phone);
    map['village'] = Variable<String>(village);
    map['is_high_risk'] = Variable<bool>(isHighRisk);
    map['is_pregnant'] = Variable<bool>(isPregnant);
    map['vaccination_required'] = Variable<bool>(vaccinationRequired);
    if (!nullToAbsent || bloodPressure != null) {
      map['blood_pressure'] = Variable<String>(bloodPressure);
    }
    if (!nullToAbsent || hemoglobin != null) {
      map['hemoglobin'] = Variable<double>(hemoglobin);
    }
    if (!nullToAbsent || bloodSugar != null) {
      map['blood_sugar'] = Variable<double>(bloodSugar);
    }
    if (!nullToAbsent || temperature != null) {
      map['temperature'] = Variable<double>(temperature);
    }
    if (!nullToAbsent || weight != null) {
      map['weight'] = Variable<double>(weight);
    }
    if (!nullToAbsent || symptoms != null) {
      map['symptoms'] = Variable<String>(symptoms);
    }
    map['previous_pregnancies'] = Variable<int>(previousPregnancies);
    map['risk_level'] = Variable<String>(riskLevel);
    map['confidence_score'] = Variable<double>(confidenceScore);
    if (!nullToAbsent || reasons != null) {
      map['reasons'] = Variable<String>(reasons);
    }
    if (!nullToAbsent || recommendations != null) {
      map['recommendations'] = Variable<String>(recommendations);
    }
    if (!nullToAbsent || nextFollowUp != null) {
      map['next_follow_up'] = Variable<DateTime>(nextFollowUp);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || placeId != null) {
      map['place_id'] = Variable<String>(placeId);
    }
    if (!nullToAbsent || district != null) {
      map['district'] = Variable<String>(district);
    }
    if (!nullToAbsent || state != null) {
      map['state'] = Variable<String>(state);
    }
    if (!nullToAbsent || country != null) {
      map['country'] = Variable<String>(country);
    }
    if (!nullToAbsent || postalCode != null) {
      map['postal_code'] = Variable<String>(postalCode);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PatientsCompanion toCompanion(bool nullToAbsent) {
    return PatientsCompanion(
      id: Value(id),
      abhaId:
          abhaId == null && nullToAbsent ? const Value.absent() : Value(abhaId),
      name: Value(name),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      dob: Value(dob),
      gender: Value(gender),
      phone: Value(phone),
      village: Value(village),
      isHighRisk: Value(isHighRisk),
      isPregnant: Value(isPregnant),
      vaccinationRequired: Value(vaccinationRequired),
      bloodPressure: bloodPressure == null && nullToAbsent
          ? const Value.absent()
          : Value(bloodPressure),
      hemoglobin: hemoglobin == null && nullToAbsent
          ? const Value.absent()
          : Value(hemoglobin),
      bloodSugar: bloodSugar == null && nullToAbsent
          ? const Value.absent()
          : Value(bloodSugar),
      temperature: temperature == null && nullToAbsent
          ? const Value.absent()
          : Value(temperature),
      weight:
          weight == null && nullToAbsent ? const Value.absent() : Value(weight),
      symptoms: symptoms == null && nullToAbsent
          ? const Value.absent()
          : Value(symptoms),
      previousPregnancies: Value(previousPregnancies),
      riskLevel: Value(riskLevel),
      confidenceScore: Value(confidenceScore),
      reasons: reasons == null && nullToAbsent
          ? const Value.absent()
          : Value(reasons),
      recommendations: recommendations == null && nullToAbsent
          ? const Value.absent()
          : Value(recommendations),
      nextFollowUp: nextFollowUp == null && nullToAbsent
          ? const Value.absent()
          : Value(nextFollowUp),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      placeId: placeId == null && nullToAbsent
          ? const Value.absent()
          : Value(placeId),
      district: district == null && nullToAbsent
          ? const Value.absent()
          : Value(district),
      state:
          state == null && nullToAbsent ? const Value.absent() : Value(state),
      country: country == null && nullToAbsent
          ? const Value.absent()
          : Value(country),
      postalCode: postalCode == null && nullToAbsent
          ? const Value.absent()
          : Value(postalCode),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Patient.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Patient(
      id: serializer.fromJson<String>(json['id']),
      abhaId: serializer.fromJson<String?>(json['abhaId']),
      name: serializer.fromJson<String>(json['name']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      dob: serializer.fromJson<DateTime>(json['dob']),
      gender: serializer.fromJson<String>(json['gender']),
      phone: serializer.fromJson<String>(json['phone']),
      village: serializer.fromJson<String>(json['village']),
      isHighRisk: serializer.fromJson<bool>(json['isHighRisk']),
      isPregnant: serializer.fromJson<bool>(json['isPregnant']),
      vaccinationRequired:
          serializer.fromJson<bool>(json['vaccinationRequired']),
      bloodPressure: serializer.fromJson<String?>(json['bloodPressure']),
      hemoglobin: serializer.fromJson<double?>(json['hemoglobin']),
      bloodSugar: serializer.fromJson<double?>(json['bloodSugar']),
      temperature: serializer.fromJson<double?>(json['temperature']),
      weight: serializer.fromJson<double?>(json['weight']),
      symptoms: serializer.fromJson<String?>(json['symptoms']),
      previousPregnancies:
          serializer.fromJson<int>(json['previousPregnancies']),
      riskLevel: serializer.fromJson<String>(json['riskLevel']),
      confidenceScore: serializer.fromJson<double>(json['confidenceScore']),
      reasons: serializer.fromJson<String?>(json['reasons']),
      recommendations: serializer.fromJson<String?>(json['recommendations']),
      nextFollowUp: serializer.fromJson<DateTime?>(json['nextFollowUp']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      placeId: serializer.fromJson<String?>(json['placeId']),
      district: serializer.fromJson<String?>(json['district']),
      state: serializer.fromJson<String?>(json['state']),
      country: serializer.fromJson<String?>(json['country']),
      postalCode: serializer.fromJson<String?>(json['postalCode']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'abhaId': serializer.toJson<String?>(abhaId),
      'name': serializer.toJson<String>(name),
      'photoPath': serializer.toJson<String?>(photoPath),
      'dob': serializer.toJson<DateTime>(dob),
      'gender': serializer.toJson<String>(gender),
      'phone': serializer.toJson<String>(phone),
      'village': serializer.toJson<String>(village),
      'isHighRisk': serializer.toJson<bool>(isHighRisk),
      'isPregnant': serializer.toJson<bool>(isPregnant),
      'vaccinationRequired': serializer.toJson<bool>(vaccinationRequired),
      'bloodPressure': serializer.toJson<String?>(bloodPressure),
      'hemoglobin': serializer.toJson<double?>(hemoglobin),
      'bloodSugar': serializer.toJson<double?>(bloodSugar),
      'temperature': serializer.toJson<double?>(temperature),
      'weight': serializer.toJson<double?>(weight),
      'symptoms': serializer.toJson<String?>(symptoms),
      'previousPregnancies': serializer.toJson<int>(previousPregnancies),
      'riskLevel': serializer.toJson<String>(riskLevel),
      'confidenceScore': serializer.toJson<double>(confidenceScore),
      'reasons': serializer.toJson<String?>(reasons),
      'recommendations': serializer.toJson<String?>(recommendations),
      'nextFollowUp': serializer.toJson<DateTime?>(nextFollowUp),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'placeId': serializer.toJson<String?>(placeId),
      'district': serializer.toJson<String?>(district),
      'state': serializer.toJson<String?>(state),
      'country': serializer.toJson<String?>(country),
      'postalCode': serializer.toJson<String?>(postalCode),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Patient copyWith(
          {String? id,
          Value<String?> abhaId = const Value.absent(),
          String? name,
          Value<String?> photoPath = const Value.absent(),
          DateTime? dob,
          String? gender,
          String? phone,
          String? village,
          bool? isHighRisk,
          bool? isPregnant,
          bool? vaccinationRequired,
          Value<String?> bloodPressure = const Value.absent(),
          Value<double?> hemoglobin = const Value.absent(),
          Value<double?> bloodSugar = const Value.absent(),
          Value<double?> temperature = const Value.absent(),
          Value<double?> weight = const Value.absent(),
          Value<String?> symptoms = const Value.absent(),
          int? previousPregnancies,
          String? riskLevel,
          double? confidenceScore,
          Value<String?> reasons = const Value.absent(),
          Value<String?> recommendations = const Value.absent(),
          Value<DateTime?> nextFollowUp = const Value.absent(),
          Value<double?> latitude = const Value.absent(),
          Value<double?> longitude = const Value.absent(),
          Value<String?> placeId = const Value.absent(),
          Value<String?> district = const Value.absent(),
          Value<String?> state = const Value.absent(),
          Value<String?> country = const Value.absent(),
          Value<String?> postalCode = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Patient(
        id: id ?? this.id,
        abhaId: abhaId.present ? abhaId.value : this.abhaId,
        name: name ?? this.name,
        photoPath: photoPath.present ? photoPath.value : this.photoPath,
        dob: dob ?? this.dob,
        gender: gender ?? this.gender,
        phone: phone ?? this.phone,
        village: village ?? this.village,
        isHighRisk: isHighRisk ?? this.isHighRisk,
        isPregnant: isPregnant ?? this.isPregnant,
        vaccinationRequired: vaccinationRequired ?? this.vaccinationRequired,
        bloodPressure:
            bloodPressure.present ? bloodPressure.value : this.bloodPressure,
        hemoglobin: hemoglobin.present ? hemoglobin.value : this.hemoglobin,
        bloodSugar: bloodSugar.present ? bloodSugar.value : this.bloodSugar,
        temperature: temperature.present ? temperature.value : this.temperature,
        weight: weight.present ? weight.value : this.weight,
        symptoms: symptoms.present ? symptoms.value : this.symptoms,
        previousPregnancies: previousPregnancies ?? this.previousPregnancies,
        riskLevel: riskLevel ?? this.riskLevel,
        confidenceScore: confidenceScore ?? this.confidenceScore,
        reasons: reasons.present ? reasons.value : this.reasons,
        recommendations: recommendations.present
            ? recommendations.value
            : this.recommendations,
        nextFollowUp:
            nextFollowUp.present ? nextFollowUp.value : this.nextFollowUp,
        latitude: latitude.present ? latitude.value : this.latitude,
        longitude: longitude.present ? longitude.value : this.longitude,
        placeId: placeId.present ? placeId.value : this.placeId,
        district: district.present ? district.value : this.district,
        state: state.present ? state.value : this.state,
        country: country.present ? country.value : this.country,
        postalCode: postalCode.present ? postalCode.value : this.postalCode,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Patient copyWithCompanion(PatientsCompanion data) {
    return Patient(
      id: data.id.present ? data.id.value : this.id,
      abhaId: data.abhaId.present ? data.abhaId.value : this.abhaId,
      name: data.name.present ? data.name.value : this.name,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      dob: data.dob.present ? data.dob.value : this.dob,
      gender: data.gender.present ? data.gender.value : this.gender,
      phone: data.phone.present ? data.phone.value : this.phone,
      village: data.village.present ? data.village.value : this.village,
      isHighRisk:
          data.isHighRisk.present ? data.isHighRisk.value : this.isHighRisk,
      isPregnant:
          data.isPregnant.present ? data.isPregnant.value : this.isPregnant,
      vaccinationRequired: data.vaccinationRequired.present
          ? data.vaccinationRequired.value
          : this.vaccinationRequired,
      bloodPressure: data.bloodPressure.present
          ? data.bloodPressure.value
          : this.bloodPressure,
      hemoglobin:
          data.hemoglobin.present ? data.hemoglobin.value : this.hemoglobin,
      bloodSugar:
          data.bloodSugar.present ? data.bloodSugar.value : this.bloodSugar,
      temperature:
          data.temperature.present ? data.temperature.value : this.temperature,
      weight: data.weight.present ? data.weight.value : this.weight,
      symptoms: data.symptoms.present ? data.symptoms.value : this.symptoms,
      previousPregnancies: data.previousPregnancies.present
          ? data.previousPregnancies.value
          : this.previousPregnancies,
      riskLevel: data.riskLevel.present ? data.riskLevel.value : this.riskLevel,
      confidenceScore: data.confidenceScore.present
          ? data.confidenceScore.value
          : this.confidenceScore,
      reasons: data.reasons.present ? data.reasons.value : this.reasons,
      recommendations: data.recommendations.present
          ? data.recommendations.value
          : this.recommendations,
      nextFollowUp: data.nextFollowUp.present
          ? data.nextFollowUp.value
          : this.nextFollowUp,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      placeId: data.placeId.present ? data.placeId.value : this.placeId,
      district: data.district.present ? data.district.value : this.district,
      state: data.state.present ? data.state.value : this.state,
      country: data.country.present ? data.country.value : this.country,
      postalCode:
          data.postalCode.present ? data.postalCode.value : this.postalCode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Patient(')
          ..write('id: $id, ')
          ..write('abhaId: $abhaId, ')
          ..write('name: $name, ')
          ..write('photoPath: $photoPath, ')
          ..write('dob: $dob, ')
          ..write('gender: $gender, ')
          ..write('phone: $phone, ')
          ..write('village: $village, ')
          ..write('isHighRisk: $isHighRisk, ')
          ..write('isPregnant: $isPregnant, ')
          ..write('vaccinationRequired: $vaccinationRequired, ')
          ..write('bloodPressure: $bloodPressure, ')
          ..write('hemoglobin: $hemoglobin, ')
          ..write('bloodSugar: $bloodSugar, ')
          ..write('temperature: $temperature, ')
          ..write('weight: $weight, ')
          ..write('symptoms: $symptoms, ')
          ..write('previousPregnancies: $previousPregnancies, ')
          ..write('riskLevel: $riskLevel, ')
          ..write('confidenceScore: $confidenceScore, ')
          ..write('reasons: $reasons, ')
          ..write('recommendations: $recommendations, ')
          ..write('nextFollowUp: $nextFollowUp, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('placeId: $placeId, ')
          ..write('district: $district, ')
          ..write('state: $state, ')
          ..write('country: $country, ')
          ..write('postalCode: $postalCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        abhaId,
        name,
        photoPath,
        dob,
        gender,
        phone,
        village,
        isHighRisk,
        isPregnant,
        vaccinationRequired,
        bloodPressure,
        hemoglobin,
        bloodSugar,
        temperature,
        weight,
        symptoms,
        previousPregnancies,
        riskLevel,
        confidenceScore,
        reasons,
        recommendations,
        nextFollowUp,
        latitude,
        longitude,
        placeId,
        district,
        state,
        country,
        postalCode,
        createdAt,
        updatedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Patient &&
          other.id == this.id &&
          other.abhaId == this.abhaId &&
          other.name == this.name &&
          other.photoPath == this.photoPath &&
          other.dob == this.dob &&
          other.gender == this.gender &&
          other.phone == this.phone &&
          other.village == this.village &&
          other.isHighRisk == this.isHighRisk &&
          other.isPregnant == this.isPregnant &&
          other.vaccinationRequired == this.vaccinationRequired &&
          other.bloodPressure == this.bloodPressure &&
          other.hemoglobin == this.hemoglobin &&
          other.bloodSugar == this.bloodSugar &&
          other.temperature == this.temperature &&
          other.weight == this.weight &&
          other.symptoms == this.symptoms &&
          other.previousPregnancies == this.previousPregnancies &&
          other.riskLevel == this.riskLevel &&
          other.confidenceScore == this.confidenceScore &&
          other.reasons == this.reasons &&
          other.recommendations == this.recommendations &&
          other.nextFollowUp == this.nextFollowUp &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.placeId == this.placeId &&
          other.district == this.district &&
          other.state == this.state &&
          other.country == this.country &&
          other.postalCode == this.postalCode &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PatientsCompanion extends UpdateCompanion<Patient> {
  final Value<String> id;
  final Value<String?> abhaId;
  final Value<String> name;
  final Value<String?> photoPath;
  final Value<DateTime> dob;
  final Value<String> gender;
  final Value<String> phone;
  final Value<String> village;
  final Value<bool> isHighRisk;
  final Value<bool> isPregnant;
  final Value<bool> vaccinationRequired;
  final Value<String?> bloodPressure;
  final Value<double?> hemoglobin;
  final Value<double?> bloodSugar;
  final Value<double?> temperature;
  final Value<double?> weight;
  final Value<String?> symptoms;
  final Value<int> previousPregnancies;
  final Value<String> riskLevel;
  final Value<double> confidenceScore;
  final Value<String?> reasons;
  final Value<String?> recommendations;
  final Value<DateTime?> nextFollowUp;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<String?> placeId;
  final Value<String?> district;
  final Value<String?> state;
  final Value<String?> country;
  final Value<String?> postalCode;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PatientsCompanion({
    this.id = const Value.absent(),
    this.abhaId = const Value.absent(),
    this.name = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.dob = const Value.absent(),
    this.gender = const Value.absent(),
    this.phone = const Value.absent(),
    this.village = const Value.absent(),
    this.isHighRisk = const Value.absent(),
    this.isPregnant = const Value.absent(),
    this.vaccinationRequired = const Value.absent(),
    this.bloodPressure = const Value.absent(),
    this.hemoglobin = const Value.absent(),
    this.bloodSugar = const Value.absent(),
    this.temperature = const Value.absent(),
    this.weight = const Value.absent(),
    this.symptoms = const Value.absent(),
    this.previousPregnancies = const Value.absent(),
    this.riskLevel = const Value.absent(),
    this.confidenceScore = const Value.absent(),
    this.reasons = const Value.absent(),
    this.recommendations = const Value.absent(),
    this.nextFollowUp = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.placeId = const Value.absent(),
    this.district = const Value.absent(),
    this.state = const Value.absent(),
    this.country = const Value.absent(),
    this.postalCode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PatientsCompanion.insert({
    required String id,
    this.abhaId = const Value.absent(),
    required String name,
    this.photoPath = const Value.absent(),
    required DateTime dob,
    required String gender,
    required String phone,
    required String village,
    this.isHighRisk = const Value.absent(),
    this.isPregnant = const Value.absent(),
    this.vaccinationRequired = const Value.absent(),
    this.bloodPressure = const Value.absent(),
    this.hemoglobin = const Value.absent(),
    this.bloodSugar = const Value.absent(),
    this.temperature = const Value.absent(),
    this.weight = const Value.absent(),
    this.symptoms = const Value.absent(),
    this.previousPregnancies = const Value.absent(),
    this.riskLevel = const Value.absent(),
    this.confidenceScore = const Value.absent(),
    this.reasons = const Value.absent(),
    this.recommendations = const Value.absent(),
    this.nextFollowUp = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.placeId = const Value.absent(),
    this.district = const Value.absent(),
    this.state = const Value.absent(),
    this.country = const Value.absent(),
    this.postalCode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        dob = Value(dob),
        gender = Value(gender),
        phone = Value(phone),
        village = Value(village);
  static Insertable<Patient> custom({
    Expression<String>? id,
    Expression<String>? abhaId,
    Expression<String>? name,
    Expression<String>? photoPath,
    Expression<DateTime>? dob,
    Expression<String>? gender,
    Expression<String>? phone,
    Expression<String>? village,
    Expression<bool>? isHighRisk,
    Expression<bool>? isPregnant,
    Expression<bool>? vaccinationRequired,
    Expression<String>? bloodPressure,
    Expression<double>? hemoglobin,
    Expression<double>? bloodSugar,
    Expression<double>? temperature,
    Expression<double>? weight,
    Expression<String>? symptoms,
    Expression<int>? previousPregnancies,
    Expression<String>? riskLevel,
    Expression<double>? confidenceScore,
    Expression<String>? reasons,
    Expression<String>? recommendations,
    Expression<DateTime>? nextFollowUp,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? placeId,
    Expression<String>? district,
    Expression<String>? state,
    Expression<String>? country,
    Expression<String>? postalCode,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (abhaId != null) 'abha_id': abhaId,
      if (name != null) 'name': name,
      if (photoPath != null) 'photo_path': photoPath,
      if (dob != null) 'dob': dob,
      if (gender != null) 'gender': gender,
      if (phone != null) 'phone': phone,
      if (village != null) 'village': village,
      if (isHighRisk != null) 'is_high_risk': isHighRisk,
      if (isPregnant != null) 'is_pregnant': isPregnant,
      if (vaccinationRequired != null)
        'vaccination_required': vaccinationRequired,
      if (bloodPressure != null) 'blood_pressure': bloodPressure,
      if (hemoglobin != null) 'hemoglobin': hemoglobin,
      if (bloodSugar != null) 'blood_sugar': bloodSugar,
      if (temperature != null) 'temperature': temperature,
      if (weight != null) 'weight': weight,
      if (symptoms != null) 'symptoms': symptoms,
      if (previousPregnancies != null)
        'previous_pregnancies': previousPregnancies,
      if (riskLevel != null) 'risk_level': riskLevel,
      if (confidenceScore != null) 'confidence_score': confidenceScore,
      if (reasons != null) 'reasons': reasons,
      if (recommendations != null) 'recommendations': recommendations,
      if (nextFollowUp != null) 'next_follow_up': nextFollowUp,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (placeId != null) 'place_id': placeId,
      if (district != null) 'district': district,
      if (state != null) 'state': state,
      if (country != null) 'country': country,
      if (postalCode != null) 'postal_code': postalCode,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PatientsCompanion copyWith(
      {Value<String>? id,
      Value<String?>? abhaId,
      Value<String>? name,
      Value<String?>? photoPath,
      Value<DateTime>? dob,
      Value<String>? gender,
      Value<String>? phone,
      Value<String>? village,
      Value<bool>? isHighRisk,
      Value<bool>? isPregnant,
      Value<bool>? vaccinationRequired,
      Value<String?>? bloodPressure,
      Value<double?>? hemoglobin,
      Value<double?>? bloodSugar,
      Value<double?>? temperature,
      Value<double?>? weight,
      Value<String?>? symptoms,
      Value<int>? previousPregnancies,
      Value<String>? riskLevel,
      Value<double>? confidenceScore,
      Value<String?>? reasons,
      Value<String?>? recommendations,
      Value<DateTime?>? nextFollowUp,
      Value<double?>? latitude,
      Value<double?>? longitude,
      Value<String?>? placeId,
      Value<String?>? district,
      Value<String?>? state,
      Value<String?>? country,
      Value<String?>? postalCode,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return PatientsCompanion(
      id: id ?? this.id,
      abhaId: abhaId ?? this.abhaId,
      name: name ?? this.name,
      photoPath: photoPath ?? this.photoPath,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      village: village ?? this.village,
      isHighRisk: isHighRisk ?? this.isHighRisk,
      isPregnant: isPregnant ?? this.isPregnant,
      vaccinationRequired: vaccinationRequired ?? this.vaccinationRequired,
      bloodPressure: bloodPressure ?? this.bloodPressure,
      hemoglobin: hemoglobin ?? this.hemoglobin,
      bloodSugar: bloodSugar ?? this.bloodSugar,
      temperature: temperature ?? this.temperature,
      weight: weight ?? this.weight,
      symptoms: symptoms ?? this.symptoms,
      previousPregnancies: previousPregnancies ?? this.previousPregnancies,
      riskLevel: riskLevel ?? this.riskLevel,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      reasons: reasons ?? this.reasons,
      recommendations: recommendations ?? this.recommendations,
      nextFollowUp: nextFollowUp ?? this.nextFollowUp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      placeId: placeId ?? this.placeId,
      district: district ?? this.district,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (abhaId.present) {
      map['abha_id'] = Variable<String>(abhaId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (dob.present) {
      map['dob'] = Variable<DateTime>(dob.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (village.present) {
      map['village'] = Variable<String>(village.value);
    }
    if (isHighRisk.present) {
      map['is_high_risk'] = Variable<bool>(isHighRisk.value);
    }
    if (isPregnant.present) {
      map['is_pregnant'] = Variable<bool>(isPregnant.value);
    }
    if (vaccinationRequired.present) {
      map['vaccination_required'] = Variable<bool>(vaccinationRequired.value);
    }
    if (bloodPressure.present) {
      map['blood_pressure'] = Variable<String>(bloodPressure.value);
    }
    if (hemoglobin.present) {
      map['hemoglobin'] = Variable<double>(hemoglobin.value);
    }
    if (bloodSugar.present) {
      map['blood_sugar'] = Variable<double>(bloodSugar.value);
    }
    if (temperature.present) {
      map['temperature'] = Variable<double>(temperature.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (symptoms.present) {
      map['symptoms'] = Variable<String>(symptoms.value);
    }
    if (previousPregnancies.present) {
      map['previous_pregnancies'] = Variable<int>(previousPregnancies.value);
    }
    if (riskLevel.present) {
      map['risk_level'] = Variable<String>(riskLevel.value);
    }
    if (confidenceScore.present) {
      map['confidence_score'] = Variable<double>(confidenceScore.value);
    }
    if (reasons.present) {
      map['reasons'] = Variable<String>(reasons.value);
    }
    if (recommendations.present) {
      map['recommendations'] = Variable<String>(recommendations.value);
    }
    if (nextFollowUp.present) {
      map['next_follow_up'] = Variable<DateTime>(nextFollowUp.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (placeId.present) {
      map['place_id'] = Variable<String>(placeId.value);
    }
    if (district.present) {
      map['district'] = Variable<String>(district.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (country.present) {
      map['country'] = Variable<String>(country.value);
    }
    if (postalCode.present) {
      map['postal_code'] = Variable<String>(postalCode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PatientsCompanion(')
          ..write('id: $id, ')
          ..write('abhaId: $abhaId, ')
          ..write('name: $name, ')
          ..write('photoPath: $photoPath, ')
          ..write('dob: $dob, ')
          ..write('gender: $gender, ')
          ..write('phone: $phone, ')
          ..write('village: $village, ')
          ..write('isHighRisk: $isHighRisk, ')
          ..write('isPregnant: $isPregnant, ')
          ..write('vaccinationRequired: $vaccinationRequired, ')
          ..write('bloodPressure: $bloodPressure, ')
          ..write('hemoglobin: $hemoglobin, ')
          ..write('bloodSugar: $bloodSugar, ')
          ..write('temperature: $temperature, ')
          ..write('weight: $weight, ')
          ..write('symptoms: $symptoms, ')
          ..write('previousPregnancies: $previousPregnancies, ')
          ..write('riskLevel: $riskLevel, ')
          ..write('confidenceScore: $confidenceScore, ')
          ..write('reasons: $reasons, ')
          ..write('recommendations: $recommendations, ')
          ..write('nextFollowUp: $nextFollowUp, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('placeId: $placeId, ')
          ..write('district: $district, ')
          ..write('state: $state, ')
          ..write('country: $country, ')
          ..write('postalCode: $postalCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VaccinationsTable extends Vaccinations
    with TableInfo<$VaccinationsTable, Vaccination> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VaccinationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _patientIdMeta =
      const VerificationMeta('patientId');
  @override
  late final GeneratedColumn<String> patientId = GeneratedColumn<String>(
      'patient_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vaccineNameMeta =
      const VerificationMeta('vaccineName');
  @override
  late final GeneratedColumn<String> vaccineName = GeneratedColumn<String>(
      'vaccine_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
      'due_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _administeredDateMeta =
      const VerificationMeta('administeredDate');
  @override
  late final GeneratedColumn<DateTime> administeredDate =
      GeneratedColumn<DateTime>('administered_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Pending'));
  static const VerificationMeta _smsSentMeta =
      const VerificationMeta('smsSent');
  @override
  late final GeneratedColumn<bool> smsSent = GeneratedColumn<bool>(
      'sms_sent', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("sms_sent" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _doseNumberMeta =
      const VerificationMeta('doseNumber');
  @override
  late final GeneratedColumn<String> doseNumber = GeneratedColumn<String>(
      'dose_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _batchNumberMeta =
      const VerificationMeta('batchNumber');
  @override
  late final GeneratedColumn<String> batchNumber = GeneratedColumn<String>(
      'batch_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _healthWorkerMeta =
      const VerificationMeta('healthWorker');
  @override
  late final GeneratedColumn<String> healthWorker = GeneratedColumn<String>(
      'health_worker', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _remarksMeta =
      const VerificationMeta('remarks');
  @override
  late final GeneratedColumn<String> remarks = GeneratedColumn<String>(
      'remarks', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        patientId,
        vaccineName,
        dueDate,
        administeredDate,
        status,
        smsSent,
        doseNumber,
        batchNumber,
        healthWorker,
        remarks
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vaccinations';
  @override
  VerificationContext validateIntegrity(Insertable<Vaccination> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(_patientIdMeta,
          patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta));
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('vaccine_name')) {
      context.handle(
          _vaccineNameMeta,
          vaccineName.isAcceptableOrUnknown(
              data['vaccine_name']!, _vaccineNameMeta));
    } else if (isInserting) {
      context.missing(_vaccineNameMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    if (data.containsKey('administered_date')) {
      context.handle(
          _administeredDateMeta,
          administeredDate.isAcceptableOrUnknown(
              data['administered_date']!, _administeredDateMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('sms_sent')) {
      context.handle(_smsSentMeta,
          smsSent.isAcceptableOrUnknown(data['sms_sent']!, _smsSentMeta));
    }
    if (data.containsKey('dose_number')) {
      context.handle(
          _doseNumberMeta,
          doseNumber.isAcceptableOrUnknown(
              data['dose_number']!, _doseNumberMeta));
    }
    if (data.containsKey('batch_number')) {
      context.handle(
          _batchNumberMeta,
          batchNumber.isAcceptableOrUnknown(
              data['batch_number']!, _batchNumberMeta));
    }
    if (data.containsKey('health_worker')) {
      context.handle(
          _healthWorkerMeta,
          healthWorker.isAcceptableOrUnknown(
              data['health_worker']!, _healthWorkerMeta));
    }
    if (data.containsKey('remarks')) {
      context.handle(_remarksMeta,
          remarks.isAcceptableOrUnknown(data['remarks']!, _remarksMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Vaccination map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Vaccination(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      patientId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}patient_id'])!,
      vaccineName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vaccine_name'])!,
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due_date'])!,
      administeredDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}administered_date']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      smsSent: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}sms_sent'])!,
      doseNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dose_number']),
      batchNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}batch_number']),
      healthWorker: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}health_worker']),
      remarks: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remarks']),
    );
  }

  @override
  $VaccinationsTable createAlias(String alias) {
    return $VaccinationsTable(attachedDatabase, alias);
  }
}

class Vaccination extends DataClass implements Insertable<Vaccination> {
  final String id;
  final String patientId;
  final String vaccineName;
  final DateTime dueDate;
  final DateTime? administeredDate;
  final String status;
  final bool smsSent;
  final String? doseNumber;
  final String? batchNumber;
  final String? healthWorker;
  final String? remarks;
  const Vaccination(
      {required this.id,
      required this.patientId,
      required this.vaccineName,
      required this.dueDate,
      this.administeredDate,
      required this.status,
      required this.smsSent,
      this.doseNumber,
      this.batchNumber,
      this.healthWorker,
      this.remarks});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['patient_id'] = Variable<String>(patientId);
    map['vaccine_name'] = Variable<String>(vaccineName);
    map['due_date'] = Variable<DateTime>(dueDate);
    if (!nullToAbsent || administeredDate != null) {
      map['administered_date'] = Variable<DateTime>(administeredDate);
    }
    map['status'] = Variable<String>(status);
    map['sms_sent'] = Variable<bool>(smsSent);
    if (!nullToAbsent || doseNumber != null) {
      map['dose_number'] = Variable<String>(doseNumber);
    }
    if (!nullToAbsent || batchNumber != null) {
      map['batch_number'] = Variable<String>(batchNumber);
    }
    if (!nullToAbsent || healthWorker != null) {
      map['health_worker'] = Variable<String>(healthWorker);
    }
    if (!nullToAbsent || remarks != null) {
      map['remarks'] = Variable<String>(remarks);
    }
    return map;
  }

  VaccinationsCompanion toCompanion(bool nullToAbsent) {
    return VaccinationsCompanion(
      id: Value(id),
      patientId: Value(patientId),
      vaccineName: Value(vaccineName),
      dueDate: Value(dueDate),
      administeredDate: administeredDate == null && nullToAbsent
          ? const Value.absent()
          : Value(administeredDate),
      status: Value(status),
      smsSent: Value(smsSent),
      doseNumber: doseNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(doseNumber),
      batchNumber: batchNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(batchNumber),
      healthWorker: healthWorker == null && nullToAbsent
          ? const Value.absent()
          : Value(healthWorker),
      remarks: remarks == null && nullToAbsent
          ? const Value.absent()
          : Value(remarks),
    );
  }

  factory Vaccination.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Vaccination(
      id: serializer.fromJson<String>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      vaccineName: serializer.fromJson<String>(json['vaccineName']),
      dueDate: serializer.fromJson<DateTime>(json['dueDate']),
      administeredDate:
          serializer.fromJson<DateTime?>(json['administeredDate']),
      status: serializer.fromJson<String>(json['status']),
      smsSent: serializer.fromJson<bool>(json['smsSent']),
      doseNumber: serializer.fromJson<String?>(json['doseNumber']),
      batchNumber: serializer.fromJson<String?>(json['batchNumber']),
      healthWorker: serializer.fromJson<String?>(json['healthWorker']),
      remarks: serializer.fromJson<String?>(json['remarks']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'patientId': serializer.toJson<String>(patientId),
      'vaccineName': serializer.toJson<String>(vaccineName),
      'dueDate': serializer.toJson<DateTime>(dueDate),
      'administeredDate': serializer.toJson<DateTime?>(administeredDate),
      'status': serializer.toJson<String>(status),
      'smsSent': serializer.toJson<bool>(smsSent),
      'doseNumber': serializer.toJson<String?>(doseNumber),
      'batchNumber': serializer.toJson<String?>(batchNumber),
      'healthWorker': serializer.toJson<String?>(healthWorker),
      'remarks': serializer.toJson<String?>(remarks),
    };
  }

  Vaccination copyWith(
          {String? id,
          String? patientId,
          String? vaccineName,
          DateTime? dueDate,
          Value<DateTime?> administeredDate = const Value.absent(),
          String? status,
          bool? smsSent,
          Value<String?> doseNumber = const Value.absent(),
          Value<String?> batchNumber = const Value.absent(),
          Value<String?> healthWorker = const Value.absent(),
          Value<String?> remarks = const Value.absent()}) =>
      Vaccination(
        id: id ?? this.id,
        patientId: patientId ?? this.patientId,
        vaccineName: vaccineName ?? this.vaccineName,
        dueDate: dueDate ?? this.dueDate,
        administeredDate: administeredDate.present
            ? administeredDate.value
            : this.administeredDate,
        status: status ?? this.status,
        smsSent: smsSent ?? this.smsSent,
        doseNumber: doseNumber.present ? doseNumber.value : this.doseNumber,
        batchNumber: batchNumber.present ? batchNumber.value : this.batchNumber,
        healthWorker:
            healthWorker.present ? healthWorker.value : this.healthWorker,
        remarks: remarks.present ? remarks.value : this.remarks,
      );
  Vaccination copyWithCompanion(VaccinationsCompanion data) {
    return Vaccination(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      vaccineName:
          data.vaccineName.present ? data.vaccineName.value : this.vaccineName,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      administeredDate: data.administeredDate.present
          ? data.administeredDate.value
          : this.administeredDate,
      status: data.status.present ? data.status.value : this.status,
      smsSent: data.smsSent.present ? data.smsSent.value : this.smsSent,
      doseNumber:
          data.doseNumber.present ? data.doseNumber.value : this.doseNumber,
      batchNumber:
          data.batchNumber.present ? data.batchNumber.value : this.batchNumber,
      healthWorker: data.healthWorker.present
          ? data.healthWorker.value
          : this.healthWorker,
      remarks: data.remarks.present ? data.remarks.value : this.remarks,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Vaccination(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('vaccineName: $vaccineName, ')
          ..write('dueDate: $dueDate, ')
          ..write('administeredDate: $administeredDate, ')
          ..write('status: $status, ')
          ..write('smsSent: $smsSent, ')
          ..write('doseNumber: $doseNumber, ')
          ..write('batchNumber: $batchNumber, ')
          ..write('healthWorker: $healthWorker, ')
          ..write('remarks: $remarks')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      patientId,
      vaccineName,
      dueDate,
      administeredDate,
      status,
      smsSent,
      doseNumber,
      batchNumber,
      healthWorker,
      remarks);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Vaccination &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.vaccineName == this.vaccineName &&
          other.dueDate == this.dueDate &&
          other.administeredDate == this.administeredDate &&
          other.status == this.status &&
          other.smsSent == this.smsSent &&
          other.doseNumber == this.doseNumber &&
          other.batchNumber == this.batchNumber &&
          other.healthWorker == this.healthWorker &&
          other.remarks == this.remarks);
}

class VaccinationsCompanion extends UpdateCompanion<Vaccination> {
  final Value<String> id;
  final Value<String> patientId;
  final Value<String> vaccineName;
  final Value<DateTime> dueDate;
  final Value<DateTime?> administeredDate;
  final Value<String> status;
  final Value<bool> smsSent;
  final Value<String?> doseNumber;
  final Value<String?> batchNumber;
  final Value<String?> healthWorker;
  final Value<String?> remarks;
  final Value<int> rowid;
  const VaccinationsCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.vaccineName = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.administeredDate = const Value.absent(),
    this.status = const Value.absent(),
    this.smsSent = const Value.absent(),
    this.doseNumber = const Value.absent(),
    this.batchNumber = const Value.absent(),
    this.healthWorker = const Value.absent(),
    this.remarks = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VaccinationsCompanion.insert({
    required String id,
    required String patientId,
    required String vaccineName,
    required DateTime dueDate,
    this.administeredDate = const Value.absent(),
    this.status = const Value.absent(),
    this.smsSent = const Value.absent(),
    this.doseNumber = const Value.absent(),
    this.batchNumber = const Value.absent(),
    this.healthWorker = const Value.absent(),
    this.remarks = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        patientId = Value(patientId),
        vaccineName = Value(vaccineName),
        dueDate = Value(dueDate);
  static Insertable<Vaccination> custom({
    Expression<String>? id,
    Expression<String>? patientId,
    Expression<String>? vaccineName,
    Expression<DateTime>? dueDate,
    Expression<DateTime>? administeredDate,
    Expression<String>? status,
    Expression<bool>? smsSent,
    Expression<String>? doseNumber,
    Expression<String>? batchNumber,
    Expression<String>? healthWorker,
    Expression<String>? remarks,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (vaccineName != null) 'vaccine_name': vaccineName,
      if (dueDate != null) 'due_date': dueDate,
      if (administeredDate != null) 'administered_date': administeredDate,
      if (status != null) 'status': status,
      if (smsSent != null) 'sms_sent': smsSent,
      if (doseNumber != null) 'dose_number': doseNumber,
      if (batchNumber != null) 'batch_number': batchNumber,
      if (healthWorker != null) 'health_worker': healthWorker,
      if (remarks != null) 'remarks': remarks,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VaccinationsCompanion copyWith(
      {Value<String>? id,
      Value<String>? patientId,
      Value<String>? vaccineName,
      Value<DateTime>? dueDate,
      Value<DateTime?>? administeredDate,
      Value<String>? status,
      Value<bool>? smsSent,
      Value<String?>? doseNumber,
      Value<String?>? batchNumber,
      Value<String?>? healthWorker,
      Value<String?>? remarks,
      Value<int>? rowid}) {
    return VaccinationsCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      vaccineName: vaccineName ?? this.vaccineName,
      dueDate: dueDate ?? this.dueDate,
      administeredDate: administeredDate ?? this.administeredDate,
      status: status ?? this.status,
      smsSent: smsSent ?? this.smsSent,
      doseNumber: doseNumber ?? this.doseNumber,
      batchNumber: batchNumber ?? this.batchNumber,
      healthWorker: healthWorker ?? this.healthWorker,
      remarks: remarks ?? this.remarks,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (vaccineName.present) {
      map['vaccine_name'] = Variable<String>(vaccineName.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (administeredDate.present) {
      map['administered_date'] = Variable<DateTime>(administeredDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (smsSent.present) {
      map['sms_sent'] = Variable<bool>(smsSent.value);
    }
    if (doseNumber.present) {
      map['dose_number'] = Variable<String>(doseNumber.value);
    }
    if (batchNumber.present) {
      map['batch_number'] = Variable<String>(batchNumber.value);
    }
    if (healthWorker.present) {
      map['health_worker'] = Variable<String>(healthWorker.value);
    }
    if (remarks.present) {
      map['remarks'] = Variable<String>(remarks.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VaccinationsCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('vaccineName: $vaccineName, ')
          ..write('dueDate: $dueDate, ')
          ..write('administeredDate: $administeredDate, ')
          ..write('status: $status, ')
          ..write('smsSent: $smsSent, ')
          ..write('doseNumber: $doseNumber, ')
          ..write('batchNumber: $batchNumber, ')
          ..write('healthWorker: $healthWorker, ')
          ..write('remarks: $remarks, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InventoryTable extends Inventory
    with TableInfo<$InventoryTable, InventoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _medicineNameMeta =
      const VerificationMeta('medicineName');
  @override
  late final GeneratedColumn<String> medicineName = GeneratedColumn<String>(
      'medicine_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _stockCountMeta =
      const VerificationMeta('stockCount');
  @override
  late final GeneratedColumn<int> stockCount = GeneratedColumn<int>(
      'stock_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _expiryDateMeta =
      const VerificationMeta('expiryDate');
  @override
  late final GeneratedColumn<DateTime> expiryDate = GeneratedColumn<DateTime>(
      'expiry_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _minThresholdMeta =
      const VerificationMeta('minThreshold');
  @override
  late final GeneratedColumn<int> minThreshold = GeneratedColumn<int>(
      'min_threshold', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(10));
  @override
  List<GeneratedColumn> get $columns =>
      [id, medicineName, stockCount, expiryDate, minThreshold];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory';
  @override
  VerificationContext validateIntegrity(Insertable<InventoryData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('medicine_name')) {
      context.handle(
          _medicineNameMeta,
          medicineName.isAcceptableOrUnknown(
              data['medicine_name']!, _medicineNameMeta));
    } else if (isInserting) {
      context.missing(_medicineNameMeta);
    }
    if (data.containsKey('stock_count')) {
      context.handle(
          _stockCountMeta,
          stockCount.isAcceptableOrUnknown(
              data['stock_count']!, _stockCountMeta));
    } else if (isInserting) {
      context.missing(_stockCountMeta);
    }
    if (data.containsKey('expiry_date')) {
      context.handle(
          _expiryDateMeta,
          expiryDate.isAcceptableOrUnknown(
              data['expiry_date']!, _expiryDateMeta));
    } else if (isInserting) {
      context.missing(_expiryDateMeta);
    }
    if (data.containsKey('min_threshold')) {
      context.handle(
          _minThresholdMeta,
          minThreshold.isAcceptableOrUnknown(
              data['min_threshold']!, _minThresholdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      medicineName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}medicine_name'])!,
      stockCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stock_count'])!,
      expiryDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}expiry_date'])!,
      minThreshold: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}min_threshold'])!,
    );
  }

  @override
  $InventoryTable createAlias(String alias) {
    return $InventoryTable(attachedDatabase, alias);
  }
}

class InventoryData extends DataClass implements Insertable<InventoryData> {
  final String id;
  final String medicineName;
  final int stockCount;
  final DateTime expiryDate;
  final int minThreshold;
  const InventoryData(
      {required this.id,
      required this.medicineName,
      required this.stockCount,
      required this.expiryDate,
      required this.minThreshold});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['medicine_name'] = Variable<String>(medicineName);
    map['stock_count'] = Variable<int>(stockCount);
    map['expiry_date'] = Variable<DateTime>(expiryDate);
    map['min_threshold'] = Variable<int>(minThreshold);
    return map;
  }

  InventoryCompanion toCompanion(bool nullToAbsent) {
    return InventoryCompanion(
      id: Value(id),
      medicineName: Value(medicineName),
      stockCount: Value(stockCount),
      expiryDate: Value(expiryDate),
      minThreshold: Value(minThreshold),
    );
  }

  factory InventoryData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryData(
      id: serializer.fromJson<String>(json['id']),
      medicineName: serializer.fromJson<String>(json['medicineName']),
      stockCount: serializer.fromJson<int>(json['stockCount']),
      expiryDate: serializer.fromJson<DateTime>(json['expiryDate']),
      minThreshold: serializer.fromJson<int>(json['minThreshold']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'medicineName': serializer.toJson<String>(medicineName),
      'stockCount': serializer.toJson<int>(stockCount),
      'expiryDate': serializer.toJson<DateTime>(expiryDate),
      'minThreshold': serializer.toJson<int>(minThreshold),
    };
  }

  InventoryData copyWith(
          {String? id,
          String? medicineName,
          int? stockCount,
          DateTime? expiryDate,
          int? minThreshold}) =>
      InventoryData(
        id: id ?? this.id,
        medicineName: medicineName ?? this.medicineName,
        stockCount: stockCount ?? this.stockCount,
        expiryDate: expiryDate ?? this.expiryDate,
        minThreshold: minThreshold ?? this.minThreshold,
      );
  InventoryData copyWithCompanion(InventoryCompanion data) {
    return InventoryData(
      id: data.id.present ? data.id.value : this.id,
      medicineName: data.medicineName.present
          ? data.medicineName.value
          : this.medicineName,
      stockCount:
          data.stockCount.present ? data.stockCount.value : this.stockCount,
      expiryDate:
          data.expiryDate.present ? data.expiryDate.value : this.expiryDate,
      minThreshold: data.minThreshold.present
          ? data.minThreshold.value
          : this.minThreshold,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryData(')
          ..write('id: $id, ')
          ..write('medicineName: $medicineName, ')
          ..write('stockCount: $stockCount, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('minThreshold: $minThreshold')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, medicineName, stockCount, expiryDate, minThreshold);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryData &&
          other.id == this.id &&
          other.medicineName == this.medicineName &&
          other.stockCount == this.stockCount &&
          other.expiryDate == this.expiryDate &&
          other.minThreshold == this.minThreshold);
}

class InventoryCompanion extends UpdateCompanion<InventoryData> {
  final Value<String> id;
  final Value<String> medicineName;
  final Value<int> stockCount;
  final Value<DateTime> expiryDate;
  final Value<int> minThreshold;
  final Value<int> rowid;
  const InventoryCompanion({
    this.id = const Value.absent(),
    this.medicineName = const Value.absent(),
    this.stockCount = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.minThreshold = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InventoryCompanion.insert({
    required String id,
    required String medicineName,
    required int stockCount,
    required DateTime expiryDate,
    this.minThreshold = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        medicineName = Value(medicineName),
        stockCount = Value(stockCount),
        expiryDate = Value(expiryDate);
  static Insertable<InventoryData> custom({
    Expression<String>? id,
    Expression<String>? medicineName,
    Expression<int>? stockCount,
    Expression<DateTime>? expiryDate,
    Expression<int>? minThreshold,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (medicineName != null) 'medicine_name': medicineName,
      if (stockCount != null) 'stock_count': stockCount,
      if (expiryDate != null) 'expiry_date': expiryDate,
      if (minThreshold != null) 'min_threshold': minThreshold,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InventoryCompanion copyWith(
      {Value<String>? id,
      Value<String>? medicineName,
      Value<int>? stockCount,
      Value<DateTime>? expiryDate,
      Value<int>? minThreshold,
      Value<int>? rowid}) {
    return InventoryCompanion(
      id: id ?? this.id,
      medicineName: medicineName ?? this.medicineName,
      stockCount: stockCount ?? this.stockCount,
      expiryDate: expiryDate ?? this.expiryDate,
      minThreshold: minThreshold ?? this.minThreshold,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (medicineName.present) {
      map['medicine_name'] = Variable<String>(medicineName.value);
    }
    if (stockCount.present) {
      map['stock_count'] = Variable<int>(stockCount.value);
    }
    if (expiryDate.present) {
      map['expiry_date'] = Variable<DateTime>(expiryDate.value);
    }
    if (minThreshold.present) {
      map['min_threshold'] = Variable<int>(minThreshold.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryCompanion(')
          ..write('id: $id, ')
          ..write('medicineName: $medicineName, ')
          ..write('stockCount: $stockCount, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('minThreshold: $minThreshold, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _targetTableMeta =
      const VerificationMeta('targetTable');
  @override
  late final GeneratedColumn<String> targetTable = GeneratedColumn<String>(
      'target_table', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recordIdMeta =
      const VerificationMeta('recordId');
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
      'record_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
      'action', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, targetTable, recordId, action, payload, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('target_table')) {
      context.handle(
          _targetTableMeta,
          targetTable.isAcceptableOrUnknown(
              data['target_table']!, _targetTableMeta));
    } else if (isInserting) {
      context.missing(_targetTableMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(_recordIdMeta,
          recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta));
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(_actionMeta,
          action.isAcceptableOrUnknown(data['action']!, _actionMeta));
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      targetTable: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_table'])!,
      recordId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}record_id'])!,
      action: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final int id;
  final String targetTable;
  final String recordId;
  final String action;
  final String payload;
  final DateTime createdAt;
  const SyncQueueData(
      {required this.id,
      required this.targetTable,
      required this.recordId,
      required this.action,
      required this.payload,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['target_table'] = Variable<String>(targetTable);
    map['record_id'] = Variable<String>(recordId);
    map['action'] = Variable<String>(action);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      targetTable: Value(targetTable),
      recordId: Value(recordId),
      action: Value(action),
      payload: Value(payload),
      createdAt: Value(createdAt),
    );
  }

  factory SyncQueueData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<int>(json['id']),
      targetTable: serializer.fromJson<String>(json['targetTable']),
      recordId: serializer.fromJson<String>(json['recordId']),
      action: serializer.fromJson<String>(json['action']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'targetTable': serializer.toJson<String>(targetTable),
      'recordId': serializer.toJson<String>(recordId),
      'action': serializer.toJson<String>(action),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SyncQueueData copyWith(
          {int? id,
          String? targetTable,
          String? recordId,
          String? action,
          String? payload,
          DateTime? createdAt}) =>
      SyncQueueData(
        id: id ?? this.id,
        targetTable: targetTable ?? this.targetTable,
        recordId: recordId ?? this.recordId,
        action: action ?? this.action,
        payload: payload ?? this.payload,
        createdAt: createdAt ?? this.createdAt,
      );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      targetTable:
          data.targetTable.present ? data.targetTable.value : this.targetTable,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      action: data.action.present ? data.action.value : this.action,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('targetTable: $targetTable, ')
          ..write('recordId: $recordId, ')
          ..write('action: $action, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, targetTable, recordId, action, payload, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.targetTable == this.targetTable &&
          other.recordId == this.recordId &&
          other.action == this.action &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<int> id;
  final Value<String> targetTable;
  final Value<String> recordId;
  final Value<String> action;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.targetTable = const Value.absent(),
    this.recordId = const Value.absent(),
    this.action = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String targetTable,
    required String recordId,
    required String action,
    required String payload,
    this.createdAt = const Value.absent(),
  })  : targetTable = Value(targetTable),
        recordId = Value(recordId),
        action = Value(action),
        payload = Value(payload);
  static Insertable<SyncQueueData> custom({
    Expression<int>? id,
    Expression<String>? targetTable,
    Expression<String>? recordId,
    Expression<String>? action,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (targetTable != null) 'target_table': targetTable,
      if (recordId != null) 'record_id': recordId,
      if (action != null) 'action': action,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SyncQueueCompanion copyWith(
      {Value<int>? id,
      Value<String>? targetTable,
      Value<String>? recordId,
      Value<String>? action,
      Value<String>? payload,
      Value<DateTime>? createdAt}) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      targetTable: targetTable ?? this.targetTable,
      recordId: recordId ?? this.recordId,
      action: action ?? this.action,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (targetTable.present) {
      map['target_table'] = Variable<String>(targetTable.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('targetTable: $targetTable, ')
          ..write('recordId: $recordId, ')
          ..write('action: $action, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SmsHistoryTable extends SmsHistory
    with TableInfo<$SmsHistoryTable, SmsHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SmsHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _recipientMeta =
      const VerificationMeta('recipient');
  @override
  late final GeneratedColumn<String> recipient = GeneratedColumn<String>(
      'recipient', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _messageTypeMeta =
      const VerificationMeta('messageType');
  @override
  late final GeneratedColumn<String> messageType = GeneratedColumn<String>(
      'message_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _messageContentMeta =
      const VerificationMeta('messageContent');
  @override
  late final GeneratedColumn<String> messageContent = GeneratedColumn<String>(
      'message_content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
      'sent_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Pending'));
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, recipient, messageType, messageContent, sentAt, status, retryCount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sms_history';
  @override
  VerificationContext validateIntegrity(Insertable<SmsHistoryData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('recipient')) {
      context.handle(_recipientMeta,
          recipient.isAcceptableOrUnknown(data['recipient']!, _recipientMeta));
    } else if (isInserting) {
      context.missing(_recipientMeta);
    }
    if (data.containsKey('message_type')) {
      context.handle(
          _messageTypeMeta,
          messageType.isAcceptableOrUnknown(
              data['message_type']!, _messageTypeMeta));
    } else if (isInserting) {
      context.missing(_messageTypeMeta);
    }
    if (data.containsKey('message_content')) {
      context.handle(
          _messageContentMeta,
          messageContent.isAcceptableOrUnknown(
              data['message_content']!, _messageContentMeta));
    } else if (isInserting) {
      context.missing(_messageContentMeta);
    }
    if (data.containsKey('sent_at')) {
      context.handle(_sentAtMeta,
          sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SmsHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SmsHistoryData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      recipient: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recipient'])!,
      messageType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_type'])!,
      messageContent: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}message_content'])!,
      sentAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}sent_at'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
    );
  }

  @override
  $SmsHistoryTable createAlias(String alias) {
    return $SmsHistoryTable(attachedDatabase, alias);
  }
}

class SmsHistoryData extends DataClass implements Insertable<SmsHistoryData> {
  final int id;
  final String recipient;
  final String messageType;
  final String messageContent;
  final DateTime sentAt;
  final String status;
  final int retryCount;
  const SmsHistoryData(
      {required this.id,
      required this.recipient,
      required this.messageType,
      required this.messageContent,
      required this.sentAt,
      required this.status,
      required this.retryCount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['recipient'] = Variable<String>(recipient);
    map['message_type'] = Variable<String>(messageType);
    map['message_content'] = Variable<String>(messageContent);
    map['sent_at'] = Variable<DateTime>(sentAt);
    map['status'] = Variable<String>(status);
    map['retry_count'] = Variable<int>(retryCount);
    return map;
  }

  SmsHistoryCompanion toCompanion(bool nullToAbsent) {
    return SmsHistoryCompanion(
      id: Value(id),
      recipient: Value(recipient),
      messageType: Value(messageType),
      messageContent: Value(messageContent),
      sentAt: Value(sentAt),
      status: Value(status),
      retryCount: Value(retryCount),
    );
  }

  factory SmsHistoryData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SmsHistoryData(
      id: serializer.fromJson<int>(json['id']),
      recipient: serializer.fromJson<String>(json['recipient']),
      messageType: serializer.fromJson<String>(json['messageType']),
      messageContent: serializer.fromJson<String>(json['messageContent']),
      sentAt: serializer.fromJson<DateTime>(json['sentAt']),
      status: serializer.fromJson<String>(json['status']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'recipient': serializer.toJson<String>(recipient),
      'messageType': serializer.toJson<String>(messageType),
      'messageContent': serializer.toJson<String>(messageContent),
      'sentAt': serializer.toJson<DateTime>(sentAt),
      'status': serializer.toJson<String>(status),
      'retryCount': serializer.toJson<int>(retryCount),
    };
  }

  SmsHistoryData copyWith(
          {int? id,
          String? recipient,
          String? messageType,
          String? messageContent,
          DateTime? sentAt,
          String? status,
          int? retryCount}) =>
      SmsHistoryData(
        id: id ?? this.id,
        recipient: recipient ?? this.recipient,
        messageType: messageType ?? this.messageType,
        messageContent: messageContent ?? this.messageContent,
        sentAt: sentAt ?? this.sentAt,
        status: status ?? this.status,
        retryCount: retryCount ?? this.retryCount,
      );
  SmsHistoryData copyWithCompanion(SmsHistoryCompanion data) {
    return SmsHistoryData(
      id: data.id.present ? data.id.value : this.id,
      recipient: data.recipient.present ? data.recipient.value : this.recipient,
      messageType:
          data.messageType.present ? data.messageType.value : this.messageType,
      messageContent: data.messageContent.present
          ? data.messageContent.value
          : this.messageContent,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      status: data.status.present ? data.status.value : this.status,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SmsHistoryData(')
          ..write('id: $id, ')
          ..write('recipient: $recipient, ')
          ..write('messageType: $messageType, ')
          ..write('messageContent: $messageContent, ')
          ..write('sentAt: $sentAt, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, recipient, messageType, messageContent, sentAt, status, retryCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SmsHistoryData &&
          other.id == this.id &&
          other.recipient == this.recipient &&
          other.messageType == this.messageType &&
          other.messageContent == this.messageContent &&
          other.sentAt == this.sentAt &&
          other.status == this.status &&
          other.retryCount == this.retryCount);
}

class SmsHistoryCompanion extends UpdateCompanion<SmsHistoryData> {
  final Value<int> id;
  final Value<String> recipient;
  final Value<String> messageType;
  final Value<String> messageContent;
  final Value<DateTime> sentAt;
  final Value<String> status;
  final Value<int> retryCount;
  const SmsHistoryCompanion({
    this.id = const Value.absent(),
    this.recipient = const Value.absent(),
    this.messageType = const Value.absent(),
    this.messageContent = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
  });
  SmsHistoryCompanion.insert({
    this.id = const Value.absent(),
    required String recipient,
    required String messageType,
    required String messageContent,
    this.sentAt = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
  })  : recipient = Value(recipient),
        messageType = Value(messageType),
        messageContent = Value(messageContent);
  static Insertable<SmsHistoryData> custom({
    Expression<int>? id,
    Expression<String>? recipient,
    Expression<String>? messageType,
    Expression<String>? messageContent,
    Expression<DateTime>? sentAt,
    Expression<String>? status,
    Expression<int>? retryCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recipient != null) 'recipient': recipient,
      if (messageType != null) 'message_type': messageType,
      if (messageContent != null) 'message_content': messageContent,
      if (sentAt != null) 'sent_at': sentAt,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
    });
  }

  SmsHistoryCompanion copyWith(
      {Value<int>? id,
      Value<String>? recipient,
      Value<String>? messageType,
      Value<String>? messageContent,
      Value<DateTime>? sentAt,
      Value<String>? status,
      Value<int>? retryCount}) {
    return SmsHistoryCompanion(
      id: id ?? this.id,
      recipient: recipient ?? this.recipient,
      messageType: messageType ?? this.messageType,
      messageContent: messageContent ?? this.messageContent,
      sentAt: sentAt ?? this.sentAt,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (recipient.present) {
      map['recipient'] = Variable<String>(recipient.value);
    }
    if (messageType.present) {
      map['message_type'] = Variable<String>(messageType.value);
    }
    if (messageContent.present) {
      map['message_content'] = Variable<String>(messageContent.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SmsHistoryCompanion(')
          ..write('id: $id, ')
          ..write('recipient: $recipient, ')
          ..write('messageType: $messageType, ')
          ..write('messageContent: $messageContent, ')
          ..write('sentAt: $sentAt, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }
}

class $AncVisitsTable extends AncVisits
    with TableInfo<$AncVisitsTable, AncVisit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AncVisitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _patientIdMeta =
      const VerificationMeta('patientId');
  @override
  late final GeneratedColumn<String> patientId = GeneratedColumn<String>(
      'patient_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _visitDateMeta =
      const VerificationMeta('visitDate');
  @override
  late final GeneratedColumn<DateTime> visitDate = GeneratedColumn<DateTime>(
      'visit_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _nextVisitDateMeta =
      const VerificationMeta('nextVisitDate');
  @override
  late final GeneratedColumn<DateTime> nextVisitDate =
      GeneratedColumn<DateTime>('next_visit_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _expectedDeliveryDateMeta =
      const VerificationMeta('expectedDeliveryDate');
  @override
  late final GeneratedColumn<String> expectedDeliveryDate =
      GeneratedColumn<String>('expected_delivery_date', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _healthWorkerMeta =
      const VerificationMeta('healthWorker');
  @override
  late final GeneratedColumn<String> healthWorker = GeneratedColumn<String>(
      'health_worker', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Pending'));
  static const VerificationMeta _smsSentMeta =
      const VerificationMeta('smsSent');
  @override
  late final GeneratedColumn<bool> smsSent = GeneratedColumn<bool>(
      'sms_sent', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("sms_sent" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        patientId,
        visitDate,
        nextVisitDate,
        expectedDeliveryDate,
        healthWorker,
        status,
        smsSent
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'anc_visits';
  @override
  VerificationContext validateIntegrity(Insertable<AncVisit> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(_patientIdMeta,
          patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta));
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('visit_date')) {
      context.handle(_visitDateMeta,
          visitDate.isAcceptableOrUnknown(data['visit_date']!, _visitDateMeta));
    } else if (isInserting) {
      context.missing(_visitDateMeta);
    }
    if (data.containsKey('next_visit_date')) {
      context.handle(
          _nextVisitDateMeta,
          nextVisitDate.isAcceptableOrUnknown(
              data['next_visit_date']!, _nextVisitDateMeta));
    }
    if (data.containsKey('expected_delivery_date')) {
      context.handle(
          _expectedDeliveryDateMeta,
          expectedDeliveryDate.isAcceptableOrUnknown(
              data['expected_delivery_date']!, _expectedDeliveryDateMeta));
    }
    if (data.containsKey('health_worker')) {
      context.handle(
          _healthWorkerMeta,
          healthWorker.isAcceptableOrUnknown(
              data['health_worker']!, _healthWorkerMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('sms_sent')) {
      context.handle(_smsSentMeta,
          smsSent.isAcceptableOrUnknown(data['sms_sent']!, _smsSentMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AncVisit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AncVisit(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      patientId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}patient_id'])!,
      visitDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}visit_date'])!,
      nextVisitDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}next_visit_date']),
      expectedDeliveryDate: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}expected_delivery_date']),
      healthWorker: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}health_worker']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      smsSent: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}sms_sent'])!,
    );
  }

  @override
  $AncVisitsTable createAlias(String alias) {
    return $AncVisitsTable(attachedDatabase, alias);
  }
}

class AncVisit extends DataClass implements Insertable<AncVisit> {
  final String id;
  final String patientId;
  final DateTime visitDate;
  final DateTime? nextVisitDate;
  final String? expectedDeliveryDate;
  final String? healthWorker;
  final String status;
  final bool smsSent;
  const AncVisit(
      {required this.id,
      required this.patientId,
      required this.visitDate,
      this.nextVisitDate,
      this.expectedDeliveryDate,
      this.healthWorker,
      required this.status,
      required this.smsSent});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['patient_id'] = Variable<String>(patientId);
    map['visit_date'] = Variable<DateTime>(visitDate);
    if (!nullToAbsent || nextVisitDate != null) {
      map['next_visit_date'] = Variable<DateTime>(nextVisitDate);
    }
    if (!nullToAbsent || expectedDeliveryDate != null) {
      map['expected_delivery_date'] = Variable<String>(expectedDeliveryDate);
    }
    if (!nullToAbsent || healthWorker != null) {
      map['health_worker'] = Variable<String>(healthWorker);
    }
    map['status'] = Variable<String>(status);
    map['sms_sent'] = Variable<bool>(smsSent);
    return map;
  }

  AncVisitsCompanion toCompanion(bool nullToAbsent) {
    return AncVisitsCompanion(
      id: Value(id),
      patientId: Value(patientId),
      visitDate: Value(visitDate),
      nextVisitDate: nextVisitDate == null && nullToAbsent
          ? const Value.absent()
          : Value(nextVisitDate),
      expectedDeliveryDate: expectedDeliveryDate == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedDeliveryDate),
      healthWorker: healthWorker == null && nullToAbsent
          ? const Value.absent()
          : Value(healthWorker),
      status: Value(status),
      smsSent: Value(smsSent),
    );
  }

  factory AncVisit.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AncVisit(
      id: serializer.fromJson<String>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      visitDate: serializer.fromJson<DateTime>(json['visitDate']),
      nextVisitDate: serializer.fromJson<DateTime?>(json['nextVisitDate']),
      expectedDeliveryDate:
          serializer.fromJson<String?>(json['expectedDeliveryDate']),
      healthWorker: serializer.fromJson<String?>(json['healthWorker']),
      status: serializer.fromJson<String>(json['status']),
      smsSent: serializer.fromJson<bool>(json['smsSent']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'patientId': serializer.toJson<String>(patientId),
      'visitDate': serializer.toJson<DateTime>(visitDate),
      'nextVisitDate': serializer.toJson<DateTime?>(nextVisitDate),
      'expectedDeliveryDate': serializer.toJson<String?>(expectedDeliveryDate),
      'healthWorker': serializer.toJson<String?>(healthWorker),
      'status': serializer.toJson<String>(status),
      'smsSent': serializer.toJson<bool>(smsSent),
    };
  }

  AncVisit copyWith(
          {String? id,
          String? patientId,
          DateTime? visitDate,
          Value<DateTime?> nextVisitDate = const Value.absent(),
          Value<String?> expectedDeliveryDate = const Value.absent(),
          Value<String?> healthWorker = const Value.absent(),
          String? status,
          bool? smsSent}) =>
      AncVisit(
        id: id ?? this.id,
        patientId: patientId ?? this.patientId,
        visitDate: visitDate ?? this.visitDate,
        nextVisitDate:
            nextVisitDate.present ? nextVisitDate.value : this.nextVisitDate,
        expectedDeliveryDate: expectedDeliveryDate.present
            ? expectedDeliveryDate.value
            : this.expectedDeliveryDate,
        healthWorker:
            healthWorker.present ? healthWorker.value : this.healthWorker,
        status: status ?? this.status,
        smsSent: smsSent ?? this.smsSent,
      );
  AncVisit copyWithCompanion(AncVisitsCompanion data) {
    return AncVisit(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      visitDate: data.visitDate.present ? data.visitDate.value : this.visitDate,
      nextVisitDate: data.nextVisitDate.present
          ? data.nextVisitDate.value
          : this.nextVisitDate,
      expectedDeliveryDate: data.expectedDeliveryDate.present
          ? data.expectedDeliveryDate.value
          : this.expectedDeliveryDate,
      healthWorker: data.healthWorker.present
          ? data.healthWorker.value
          : this.healthWorker,
      status: data.status.present ? data.status.value : this.status,
      smsSent: data.smsSent.present ? data.smsSent.value : this.smsSent,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AncVisit(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('visitDate: $visitDate, ')
          ..write('nextVisitDate: $nextVisitDate, ')
          ..write('expectedDeliveryDate: $expectedDeliveryDate, ')
          ..write('healthWorker: $healthWorker, ')
          ..write('status: $status, ')
          ..write('smsSent: $smsSent')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, patientId, visitDate, nextVisitDate,
      expectedDeliveryDate, healthWorker, status, smsSent);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AncVisit &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.visitDate == this.visitDate &&
          other.nextVisitDate == this.nextVisitDate &&
          other.expectedDeliveryDate == this.expectedDeliveryDate &&
          other.healthWorker == this.healthWorker &&
          other.status == this.status &&
          other.smsSent == this.smsSent);
}

class AncVisitsCompanion extends UpdateCompanion<AncVisit> {
  final Value<String> id;
  final Value<String> patientId;
  final Value<DateTime> visitDate;
  final Value<DateTime?> nextVisitDate;
  final Value<String?> expectedDeliveryDate;
  final Value<String?> healthWorker;
  final Value<String> status;
  final Value<bool> smsSent;
  final Value<int> rowid;
  const AncVisitsCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.visitDate = const Value.absent(),
    this.nextVisitDate = const Value.absent(),
    this.expectedDeliveryDate = const Value.absent(),
    this.healthWorker = const Value.absent(),
    this.status = const Value.absent(),
    this.smsSent = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AncVisitsCompanion.insert({
    required String id,
    required String patientId,
    required DateTime visitDate,
    this.nextVisitDate = const Value.absent(),
    this.expectedDeliveryDate = const Value.absent(),
    this.healthWorker = const Value.absent(),
    this.status = const Value.absent(),
    this.smsSent = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        patientId = Value(patientId),
        visitDate = Value(visitDate);
  static Insertable<AncVisit> custom({
    Expression<String>? id,
    Expression<String>? patientId,
    Expression<DateTime>? visitDate,
    Expression<DateTime>? nextVisitDate,
    Expression<String>? expectedDeliveryDate,
    Expression<String>? healthWorker,
    Expression<String>? status,
    Expression<bool>? smsSent,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (visitDate != null) 'visit_date': visitDate,
      if (nextVisitDate != null) 'next_visit_date': nextVisitDate,
      if (expectedDeliveryDate != null)
        'expected_delivery_date': expectedDeliveryDate,
      if (healthWorker != null) 'health_worker': healthWorker,
      if (status != null) 'status': status,
      if (smsSent != null) 'sms_sent': smsSent,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AncVisitsCompanion copyWith(
      {Value<String>? id,
      Value<String>? patientId,
      Value<DateTime>? visitDate,
      Value<DateTime?>? nextVisitDate,
      Value<String?>? expectedDeliveryDate,
      Value<String?>? healthWorker,
      Value<String>? status,
      Value<bool>? smsSent,
      Value<int>? rowid}) {
    return AncVisitsCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      visitDate: visitDate ?? this.visitDate,
      nextVisitDate: nextVisitDate ?? this.nextVisitDate,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      healthWorker: healthWorker ?? this.healthWorker,
      status: status ?? this.status,
      smsSent: smsSent ?? this.smsSent,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (visitDate.present) {
      map['visit_date'] = Variable<DateTime>(visitDate.value);
    }
    if (nextVisitDate.present) {
      map['next_visit_date'] = Variable<DateTime>(nextVisitDate.value);
    }
    if (expectedDeliveryDate.present) {
      map['expected_delivery_date'] =
          Variable<String>(expectedDeliveryDate.value);
    }
    if (healthWorker.present) {
      map['health_worker'] = Variable<String>(healthWorker.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (smsSent.present) {
      map['sms_sent'] = Variable<bool>(smsSent.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AncVisitsCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('visitDate: $visitDate, ')
          ..write('nextVisitDate: $nextVisitDate, ')
          ..write('expectedDeliveryDate: $expectedDeliveryDate, ')
          ..write('healthWorker: $healthWorker, ')
          ..write('status: $status, ')
          ..write('smsSent: $smsSent, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDatabase extends GeneratedDatabase {
  _$LocalDatabase(QueryExecutor e) : super(e);
  $LocalDatabaseManager get managers => $LocalDatabaseManager(this);
  late final $PatientsTable patients = $PatientsTable(this);
  late final $VaccinationsTable vaccinations = $VaccinationsTable(this);
  late final $InventoryTable inventory = $InventoryTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $SmsHistoryTable smsHistory = $SmsHistoryTable(this);
  late final $AncVisitsTable ancVisits = $AncVisitsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [patients, vaccinations, inventory, syncQueue, smsHistory, ancVisits];
}

typedef $$PatientsTableCreateCompanionBuilder = PatientsCompanion Function({
  required String id,
  Value<String?> abhaId,
  required String name,
  Value<String?> photoPath,
  required DateTime dob,
  required String gender,
  required String phone,
  required String village,
  Value<bool> isHighRisk,
  Value<bool> isPregnant,
  Value<bool> vaccinationRequired,
  Value<String?> bloodPressure,
  Value<double?> hemoglobin,
  Value<double?> bloodSugar,
  Value<double?> temperature,
  Value<double?> weight,
  Value<String?> symptoms,
  Value<int> previousPregnancies,
  Value<String> riskLevel,
  Value<double> confidenceScore,
  Value<String?> reasons,
  Value<String?> recommendations,
  Value<DateTime?> nextFollowUp,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<String?> placeId,
  Value<String?> district,
  Value<String?> state,
  Value<String?> country,
  Value<String?> postalCode,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$PatientsTableUpdateCompanionBuilder = PatientsCompanion Function({
  Value<String> id,
  Value<String?> abhaId,
  Value<String> name,
  Value<String?> photoPath,
  Value<DateTime> dob,
  Value<String> gender,
  Value<String> phone,
  Value<String> village,
  Value<bool> isHighRisk,
  Value<bool> isPregnant,
  Value<bool> vaccinationRequired,
  Value<String?> bloodPressure,
  Value<double?> hemoglobin,
  Value<double?> bloodSugar,
  Value<double?> temperature,
  Value<double?> weight,
  Value<String?> symptoms,
  Value<int> previousPregnancies,
  Value<String> riskLevel,
  Value<double> confidenceScore,
  Value<String?> reasons,
  Value<String?> recommendations,
  Value<DateTime?> nextFollowUp,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<String?> placeId,
  Value<String?> district,
  Value<String?> state,
  Value<String?> country,
  Value<String?> postalCode,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$PatientsTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $PatientsTable,
    Patient,
    $$PatientsTableFilterComposer,
    $$PatientsTableOrderingComposer,
    $$PatientsTableCreateCompanionBuilder,
    $$PatientsTableUpdateCompanionBuilder> {
  $$PatientsTableTableManager(_$LocalDatabase db, $PatientsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$PatientsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$PatientsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> abhaId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> photoPath = const Value.absent(),
            Value<DateTime> dob = const Value.absent(),
            Value<String> gender = const Value.absent(),
            Value<String> phone = const Value.absent(),
            Value<String> village = const Value.absent(),
            Value<bool> isHighRisk = const Value.absent(),
            Value<bool> isPregnant = const Value.absent(),
            Value<bool> vaccinationRequired = const Value.absent(),
            Value<String?> bloodPressure = const Value.absent(),
            Value<double?> hemoglobin = const Value.absent(),
            Value<double?> bloodSugar = const Value.absent(),
            Value<double?> temperature = const Value.absent(),
            Value<double?> weight = const Value.absent(),
            Value<String?> symptoms = const Value.absent(),
            Value<int> previousPregnancies = const Value.absent(),
            Value<String> riskLevel = const Value.absent(),
            Value<double> confidenceScore = const Value.absent(),
            Value<String?> reasons = const Value.absent(),
            Value<String?> recommendations = const Value.absent(),
            Value<DateTime?> nextFollowUp = const Value.absent(),
            Value<double?> latitude = const Value.absent(),
            Value<double?> longitude = const Value.absent(),
            Value<String?> placeId = const Value.absent(),
            Value<String?> district = const Value.absent(),
            Value<String?> state = const Value.absent(),
            Value<String?> country = const Value.absent(),
            Value<String?> postalCode = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PatientsCompanion(
            id: id,
            abhaId: abhaId,
            name: name,
            photoPath: photoPath,
            dob: dob,
            gender: gender,
            phone: phone,
            village: village,
            isHighRisk: isHighRisk,
            isPregnant: isPregnant,
            vaccinationRequired: vaccinationRequired,
            bloodPressure: bloodPressure,
            hemoglobin: hemoglobin,
            bloodSugar: bloodSugar,
            temperature: temperature,
            weight: weight,
            symptoms: symptoms,
            previousPregnancies: previousPregnancies,
            riskLevel: riskLevel,
            confidenceScore: confidenceScore,
            reasons: reasons,
            recommendations: recommendations,
            nextFollowUp: nextFollowUp,
            latitude: latitude,
            longitude: longitude,
            placeId: placeId,
            district: district,
            state: state,
            country: country,
            postalCode: postalCode,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> abhaId = const Value.absent(),
            required String name,
            Value<String?> photoPath = const Value.absent(),
            required DateTime dob,
            required String gender,
            required String phone,
            required String village,
            Value<bool> isHighRisk = const Value.absent(),
            Value<bool> isPregnant = const Value.absent(),
            Value<bool> vaccinationRequired = const Value.absent(),
            Value<String?> bloodPressure = const Value.absent(),
            Value<double?> hemoglobin = const Value.absent(),
            Value<double?> bloodSugar = const Value.absent(),
            Value<double?> temperature = const Value.absent(),
            Value<double?> weight = const Value.absent(),
            Value<String?> symptoms = const Value.absent(),
            Value<int> previousPregnancies = const Value.absent(),
            Value<String> riskLevel = const Value.absent(),
            Value<double> confidenceScore = const Value.absent(),
            Value<String?> reasons = const Value.absent(),
            Value<String?> recommendations = const Value.absent(),
            Value<DateTime?> nextFollowUp = const Value.absent(),
            Value<double?> latitude = const Value.absent(),
            Value<double?> longitude = const Value.absent(),
            Value<String?> placeId = const Value.absent(),
            Value<String?> district = const Value.absent(),
            Value<String?> state = const Value.absent(),
            Value<String?> country = const Value.absent(),
            Value<String?> postalCode = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PatientsCompanion.insert(
            id: id,
            abhaId: abhaId,
            name: name,
            photoPath: photoPath,
            dob: dob,
            gender: gender,
            phone: phone,
            village: village,
            isHighRisk: isHighRisk,
            isPregnant: isPregnant,
            vaccinationRequired: vaccinationRequired,
            bloodPressure: bloodPressure,
            hemoglobin: hemoglobin,
            bloodSugar: bloodSugar,
            temperature: temperature,
            weight: weight,
            symptoms: symptoms,
            previousPregnancies: previousPregnancies,
            riskLevel: riskLevel,
            confidenceScore: confidenceScore,
            reasons: reasons,
            recommendations: recommendations,
            nextFollowUp: nextFollowUp,
            latitude: latitude,
            longitude: longitude,
            placeId: placeId,
            district: district,
            state: state,
            country: country,
            postalCode: postalCode,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
        ));
}

class $$PatientsTableFilterComposer
    extends FilterComposer<_$LocalDatabase, $PatientsTable> {
  $$PatientsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get abhaId => $state.composableBuilder(
      column: $state.table.abhaId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get photoPath => $state.composableBuilder(
      column: $state.table.photoPath,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dob => $state.composableBuilder(
      column: $state.table.dob,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get gender => $state.composableBuilder(
      column: $state.table.gender,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get phone => $state.composableBuilder(
      column: $state.table.phone,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get village => $state.composableBuilder(
      column: $state.table.village,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isHighRisk => $state.composableBuilder(
      column: $state.table.isHighRisk,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isPregnant => $state.composableBuilder(
      column: $state.table.isPregnant,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get vaccinationRequired => $state.composableBuilder(
      column: $state.table.vaccinationRequired,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get bloodPressure => $state.composableBuilder(
      column: $state.table.bloodPressure,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get hemoglobin => $state.composableBuilder(
      column: $state.table.hemoglobin,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get bloodSugar => $state.composableBuilder(
      column: $state.table.bloodSugar,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get temperature => $state.composableBuilder(
      column: $state.table.temperature,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get weight => $state.composableBuilder(
      column: $state.table.weight,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get symptoms => $state.composableBuilder(
      column: $state.table.symptoms,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get previousPregnancies => $state.composableBuilder(
      column: $state.table.previousPregnancies,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get riskLevel => $state.composableBuilder(
      column: $state.table.riskLevel,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get confidenceScore => $state.composableBuilder(
      column: $state.table.confidenceScore,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get reasons => $state.composableBuilder(
      column: $state.table.reasons,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get recommendations => $state.composableBuilder(
      column: $state.table.recommendations,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get nextFollowUp => $state.composableBuilder(
      column: $state.table.nextFollowUp,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get latitude => $state.composableBuilder(
      column: $state.table.latitude,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get longitude => $state.composableBuilder(
      column: $state.table.longitude,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get placeId => $state.composableBuilder(
      column: $state.table.placeId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get district => $state.composableBuilder(
      column: $state.table.district,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get state => $state.composableBuilder(
      column: $state.table.state,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get country => $state.composableBuilder(
      column: $state.table.country,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get postalCode => $state.composableBuilder(
      column: $state.table.postalCode,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$PatientsTableOrderingComposer
    extends OrderingComposer<_$LocalDatabase, $PatientsTable> {
  $$PatientsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get abhaId => $state.composableBuilder(
      column: $state.table.abhaId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get photoPath => $state.composableBuilder(
      column: $state.table.photoPath,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dob => $state.composableBuilder(
      column: $state.table.dob,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get gender => $state.composableBuilder(
      column: $state.table.gender,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get phone => $state.composableBuilder(
      column: $state.table.phone,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get village => $state.composableBuilder(
      column: $state.table.village,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isHighRisk => $state.composableBuilder(
      column: $state.table.isHighRisk,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isPregnant => $state.composableBuilder(
      column: $state.table.isPregnant,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get vaccinationRequired => $state.composableBuilder(
      column: $state.table.vaccinationRequired,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get bloodPressure => $state.composableBuilder(
      column: $state.table.bloodPressure,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get hemoglobin => $state.composableBuilder(
      column: $state.table.hemoglobin,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get bloodSugar => $state.composableBuilder(
      column: $state.table.bloodSugar,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get temperature => $state.composableBuilder(
      column: $state.table.temperature,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get weight => $state.composableBuilder(
      column: $state.table.weight,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get symptoms => $state.composableBuilder(
      column: $state.table.symptoms,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get previousPregnancies => $state.composableBuilder(
      column: $state.table.previousPregnancies,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get riskLevel => $state.composableBuilder(
      column: $state.table.riskLevel,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get confidenceScore => $state.composableBuilder(
      column: $state.table.confidenceScore,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get reasons => $state.composableBuilder(
      column: $state.table.reasons,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get recommendations => $state.composableBuilder(
      column: $state.table.recommendations,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get nextFollowUp => $state.composableBuilder(
      column: $state.table.nextFollowUp,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get latitude => $state.composableBuilder(
      column: $state.table.latitude,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get longitude => $state.composableBuilder(
      column: $state.table.longitude,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get placeId => $state.composableBuilder(
      column: $state.table.placeId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get district => $state.composableBuilder(
      column: $state.table.district,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get state => $state.composableBuilder(
      column: $state.table.state,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get country => $state.composableBuilder(
      column: $state.table.country,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get postalCode => $state.composableBuilder(
      column: $state.table.postalCode,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$VaccinationsTableCreateCompanionBuilder = VaccinationsCompanion
    Function({
  required String id,
  required String patientId,
  required String vaccineName,
  required DateTime dueDate,
  Value<DateTime?> administeredDate,
  Value<String> status,
  Value<bool> smsSent,
  Value<String?> doseNumber,
  Value<String?> batchNumber,
  Value<String?> healthWorker,
  Value<String?> remarks,
  Value<int> rowid,
});
typedef $$VaccinationsTableUpdateCompanionBuilder = VaccinationsCompanion
    Function({
  Value<String> id,
  Value<String> patientId,
  Value<String> vaccineName,
  Value<DateTime> dueDate,
  Value<DateTime?> administeredDate,
  Value<String> status,
  Value<bool> smsSent,
  Value<String?> doseNumber,
  Value<String?> batchNumber,
  Value<String?> healthWorker,
  Value<String?> remarks,
  Value<int> rowid,
});

class $$VaccinationsTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $VaccinationsTable,
    Vaccination,
    $$VaccinationsTableFilterComposer,
    $$VaccinationsTableOrderingComposer,
    $$VaccinationsTableCreateCompanionBuilder,
    $$VaccinationsTableUpdateCompanionBuilder> {
  $$VaccinationsTableTableManager(_$LocalDatabase db, $VaccinationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$VaccinationsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$VaccinationsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> patientId = const Value.absent(),
            Value<String> vaccineName = const Value.absent(),
            Value<DateTime> dueDate = const Value.absent(),
            Value<DateTime?> administeredDate = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<bool> smsSent = const Value.absent(),
            Value<String?> doseNumber = const Value.absent(),
            Value<String?> batchNumber = const Value.absent(),
            Value<String?> healthWorker = const Value.absent(),
            Value<String?> remarks = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VaccinationsCompanion(
            id: id,
            patientId: patientId,
            vaccineName: vaccineName,
            dueDate: dueDate,
            administeredDate: administeredDate,
            status: status,
            smsSent: smsSent,
            doseNumber: doseNumber,
            batchNumber: batchNumber,
            healthWorker: healthWorker,
            remarks: remarks,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String patientId,
            required String vaccineName,
            required DateTime dueDate,
            Value<DateTime?> administeredDate = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<bool> smsSent = const Value.absent(),
            Value<String?> doseNumber = const Value.absent(),
            Value<String?> batchNumber = const Value.absent(),
            Value<String?> healthWorker = const Value.absent(),
            Value<String?> remarks = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VaccinationsCompanion.insert(
            id: id,
            patientId: patientId,
            vaccineName: vaccineName,
            dueDate: dueDate,
            administeredDate: administeredDate,
            status: status,
            smsSent: smsSent,
            doseNumber: doseNumber,
            batchNumber: batchNumber,
            healthWorker: healthWorker,
            remarks: remarks,
            rowid: rowid,
          ),
        ));
}

class $$VaccinationsTableFilterComposer
    extends FilterComposer<_$LocalDatabase, $VaccinationsTable> {
  $$VaccinationsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get patientId => $state.composableBuilder(
      column: $state.table.patientId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get vaccineName => $state.composableBuilder(
      column: $state.table.vaccineName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get dueDate => $state.composableBuilder(
      column: $state.table.dueDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get administeredDate => $state.composableBuilder(
      column: $state.table.administeredDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get smsSent => $state.composableBuilder(
      column: $state.table.smsSent,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get doseNumber => $state.composableBuilder(
      column: $state.table.doseNumber,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get batchNumber => $state.composableBuilder(
      column: $state.table.batchNumber,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get healthWorker => $state.composableBuilder(
      column: $state.table.healthWorker,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get remarks => $state.composableBuilder(
      column: $state.table.remarks,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$VaccinationsTableOrderingComposer
    extends OrderingComposer<_$LocalDatabase, $VaccinationsTable> {
  $$VaccinationsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get patientId => $state.composableBuilder(
      column: $state.table.patientId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get vaccineName => $state.composableBuilder(
      column: $state.table.vaccineName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get dueDate => $state.composableBuilder(
      column: $state.table.dueDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get administeredDate => $state.composableBuilder(
      column: $state.table.administeredDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get smsSent => $state.composableBuilder(
      column: $state.table.smsSent,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get doseNumber => $state.composableBuilder(
      column: $state.table.doseNumber,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get batchNumber => $state.composableBuilder(
      column: $state.table.batchNumber,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get healthWorker => $state.composableBuilder(
      column: $state.table.healthWorker,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get remarks => $state.composableBuilder(
      column: $state.table.remarks,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$InventoryTableCreateCompanionBuilder = InventoryCompanion Function({
  required String id,
  required String medicineName,
  required int stockCount,
  required DateTime expiryDate,
  Value<int> minThreshold,
  Value<int> rowid,
});
typedef $$InventoryTableUpdateCompanionBuilder = InventoryCompanion Function({
  Value<String> id,
  Value<String> medicineName,
  Value<int> stockCount,
  Value<DateTime> expiryDate,
  Value<int> minThreshold,
  Value<int> rowid,
});

class $$InventoryTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $InventoryTable,
    InventoryData,
    $$InventoryTableFilterComposer,
    $$InventoryTableOrderingComposer,
    $$InventoryTableCreateCompanionBuilder,
    $$InventoryTableUpdateCompanionBuilder> {
  $$InventoryTableTableManager(_$LocalDatabase db, $InventoryTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$InventoryTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$InventoryTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> medicineName = const Value.absent(),
            Value<int> stockCount = const Value.absent(),
            Value<DateTime> expiryDate = const Value.absent(),
            Value<int> minThreshold = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InventoryCompanion(
            id: id,
            medicineName: medicineName,
            stockCount: stockCount,
            expiryDate: expiryDate,
            minThreshold: minThreshold,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String medicineName,
            required int stockCount,
            required DateTime expiryDate,
            Value<int> minThreshold = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InventoryCompanion.insert(
            id: id,
            medicineName: medicineName,
            stockCount: stockCount,
            expiryDate: expiryDate,
            minThreshold: minThreshold,
            rowid: rowid,
          ),
        ));
}

class $$InventoryTableFilterComposer
    extends FilterComposer<_$LocalDatabase, $InventoryTable> {
  $$InventoryTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get medicineName => $state.composableBuilder(
      column: $state.table.medicineName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get stockCount => $state.composableBuilder(
      column: $state.table.stockCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get expiryDate => $state.composableBuilder(
      column: $state.table.expiryDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get minThreshold => $state.composableBuilder(
      column: $state.table.minThreshold,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$InventoryTableOrderingComposer
    extends OrderingComposer<_$LocalDatabase, $InventoryTable> {
  $$InventoryTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get medicineName => $state.composableBuilder(
      column: $state.table.medicineName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get stockCount => $state.composableBuilder(
      column: $state.table.stockCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get expiryDate => $state.composableBuilder(
      column: $state.table.expiryDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get minThreshold => $state.composableBuilder(
      column: $state.table.minThreshold,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  required String targetTable,
  required String recordId,
  required String action,
  required String payload,
  Value<DateTime> createdAt,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  Value<String> targetTable,
  Value<String> recordId,
  Value<String> action,
  Value<String> payload,
  Value<DateTime> createdAt,
});

class $$SyncQueueTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $SyncQueueTable,
    SyncQueueData,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder> {
  $$SyncQueueTableTableManager(_$LocalDatabase db, $SyncQueueTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$SyncQueueTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$SyncQueueTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> targetTable = const Value.absent(),
            Value<String> recordId = const Value.absent(),
            Value<String> action = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              SyncQueueCompanion(
            id: id,
            targetTable: targetTable,
            recordId: recordId,
            action: action,
            payload: payload,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String targetTable,
            required String recordId,
            required String action,
            required String payload,
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              SyncQueueCompanion.insert(
            id: id,
            targetTable: targetTable,
            recordId: recordId,
            action: action,
            payload: payload,
            createdAt: createdAt,
          ),
        ));
}

class $$SyncQueueTableFilterComposer
    extends FilterComposer<_$LocalDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get targetTable => $state.composableBuilder(
      column: $state.table.targetTable,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get recordId => $state.composableBuilder(
      column: $state.table.recordId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get action => $state.composableBuilder(
      column: $state.table.action,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get payload => $state.composableBuilder(
      column: $state.table.payload,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$SyncQueueTableOrderingComposer
    extends OrderingComposer<_$LocalDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get targetTable => $state.composableBuilder(
      column: $state.table.targetTable,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get recordId => $state.composableBuilder(
      column: $state.table.recordId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get action => $state.composableBuilder(
      column: $state.table.action,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get payload => $state.composableBuilder(
      column: $state.table.payload,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$SmsHistoryTableCreateCompanionBuilder = SmsHistoryCompanion Function({
  Value<int> id,
  required String recipient,
  required String messageType,
  required String messageContent,
  Value<DateTime> sentAt,
  Value<String> status,
  Value<int> retryCount,
});
typedef $$SmsHistoryTableUpdateCompanionBuilder = SmsHistoryCompanion Function({
  Value<int> id,
  Value<String> recipient,
  Value<String> messageType,
  Value<String> messageContent,
  Value<DateTime> sentAt,
  Value<String> status,
  Value<int> retryCount,
});

class $$SmsHistoryTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $SmsHistoryTable,
    SmsHistoryData,
    $$SmsHistoryTableFilterComposer,
    $$SmsHistoryTableOrderingComposer,
    $$SmsHistoryTableCreateCompanionBuilder,
    $$SmsHistoryTableUpdateCompanionBuilder> {
  $$SmsHistoryTableTableManager(_$LocalDatabase db, $SmsHistoryTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$SmsHistoryTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$SmsHistoryTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> recipient = const Value.absent(),
            Value<String> messageType = const Value.absent(),
            Value<String> messageContent = const Value.absent(),
            Value<DateTime> sentAt = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
          }) =>
              SmsHistoryCompanion(
            id: id,
            recipient: recipient,
            messageType: messageType,
            messageContent: messageContent,
            sentAt: sentAt,
            status: status,
            retryCount: retryCount,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String recipient,
            required String messageType,
            required String messageContent,
            Value<DateTime> sentAt = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
          }) =>
              SmsHistoryCompanion.insert(
            id: id,
            recipient: recipient,
            messageType: messageType,
            messageContent: messageContent,
            sentAt: sentAt,
            status: status,
            retryCount: retryCount,
          ),
        ));
}

class $$SmsHistoryTableFilterComposer
    extends FilterComposer<_$LocalDatabase, $SmsHistoryTable> {
  $$SmsHistoryTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get recipient => $state.composableBuilder(
      column: $state.table.recipient,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get messageType => $state.composableBuilder(
      column: $state.table.messageType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get messageContent => $state.composableBuilder(
      column: $state.table.messageContent,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get sentAt => $state.composableBuilder(
      column: $state.table.sentAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get retryCount => $state.composableBuilder(
      column: $state.table.retryCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$SmsHistoryTableOrderingComposer
    extends OrderingComposer<_$LocalDatabase, $SmsHistoryTable> {
  $$SmsHistoryTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get recipient => $state.composableBuilder(
      column: $state.table.recipient,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get messageType => $state.composableBuilder(
      column: $state.table.messageType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get messageContent => $state.composableBuilder(
      column: $state.table.messageContent,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get sentAt => $state.composableBuilder(
      column: $state.table.sentAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get retryCount => $state.composableBuilder(
      column: $state.table.retryCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$AncVisitsTableCreateCompanionBuilder = AncVisitsCompanion Function({
  required String id,
  required String patientId,
  required DateTime visitDate,
  Value<DateTime?> nextVisitDate,
  Value<String?> expectedDeliveryDate,
  Value<String?> healthWorker,
  Value<String> status,
  Value<bool> smsSent,
  Value<int> rowid,
});
typedef $$AncVisitsTableUpdateCompanionBuilder = AncVisitsCompanion Function({
  Value<String> id,
  Value<String> patientId,
  Value<DateTime> visitDate,
  Value<DateTime?> nextVisitDate,
  Value<String?> expectedDeliveryDate,
  Value<String?> healthWorker,
  Value<String> status,
  Value<bool> smsSent,
  Value<int> rowid,
});

class $$AncVisitsTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $AncVisitsTable,
    AncVisit,
    $$AncVisitsTableFilterComposer,
    $$AncVisitsTableOrderingComposer,
    $$AncVisitsTableCreateCompanionBuilder,
    $$AncVisitsTableUpdateCompanionBuilder> {
  $$AncVisitsTableTableManager(_$LocalDatabase db, $AncVisitsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$AncVisitsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$AncVisitsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> patientId = const Value.absent(),
            Value<DateTime> visitDate = const Value.absent(),
            Value<DateTime?> nextVisitDate = const Value.absent(),
            Value<String?> expectedDeliveryDate = const Value.absent(),
            Value<String?> healthWorker = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<bool> smsSent = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AncVisitsCompanion(
            id: id,
            patientId: patientId,
            visitDate: visitDate,
            nextVisitDate: nextVisitDate,
            expectedDeliveryDate: expectedDeliveryDate,
            healthWorker: healthWorker,
            status: status,
            smsSent: smsSent,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String patientId,
            required DateTime visitDate,
            Value<DateTime?> nextVisitDate = const Value.absent(),
            Value<String?> expectedDeliveryDate = const Value.absent(),
            Value<String?> healthWorker = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<bool> smsSent = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AncVisitsCompanion.insert(
            id: id,
            patientId: patientId,
            visitDate: visitDate,
            nextVisitDate: nextVisitDate,
            expectedDeliveryDate: expectedDeliveryDate,
            healthWorker: healthWorker,
            status: status,
            smsSent: smsSent,
            rowid: rowid,
          ),
        ));
}

class $$AncVisitsTableFilterComposer
    extends FilterComposer<_$LocalDatabase, $AncVisitsTable> {
  $$AncVisitsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get patientId => $state.composableBuilder(
      column: $state.table.patientId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get visitDate => $state.composableBuilder(
      column: $state.table.visitDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get nextVisitDate => $state.composableBuilder(
      column: $state.table.nextVisitDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get expectedDeliveryDate => $state.composableBuilder(
      column: $state.table.expectedDeliveryDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get healthWorker => $state.composableBuilder(
      column: $state.table.healthWorker,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get smsSent => $state.composableBuilder(
      column: $state.table.smsSent,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$AncVisitsTableOrderingComposer
    extends OrderingComposer<_$LocalDatabase, $AncVisitsTable> {
  $$AncVisitsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get patientId => $state.composableBuilder(
      column: $state.table.patientId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get visitDate => $state.composableBuilder(
      column: $state.table.visitDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get nextVisitDate => $state.composableBuilder(
      column: $state.table.nextVisitDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get expectedDeliveryDate => $state.composableBuilder(
      column: $state.table.expectedDeliveryDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get healthWorker => $state.composableBuilder(
      column: $state.table.healthWorker,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get smsSent => $state.composableBuilder(
      column: $state.table.smsSent,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $LocalDatabaseManager {
  final _$LocalDatabase _db;
  $LocalDatabaseManager(this._db);
  $$PatientsTableTableManager get patients =>
      $$PatientsTableTableManager(_db, _db.patients);
  $$VaccinationsTableTableManager get vaccinations =>
      $$VaccinationsTableTableManager(_db, _db.vaccinations);
  $$InventoryTableTableManager get inventory =>
      $$InventoryTableTableManager(_db, _db.inventory);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$SmsHistoryTableTableManager get smsHistory =>
      $$SmsHistoryTableTableManager(_db, _db.smsHistory);
  $$AncVisitsTableTableManager get ancVisits =>
      $$AncVisitsTableTableManager(_db, _db.ancVisits);
}
