class TokenModel {
  final String issuer;
  final String account;
  final String secret;
  final int digits;
  final int period;


  TokenModel({
    required this.issuer,
    required this.account,
    required this.secret,
    this.digits = 6,
    this.period = 30,
  });


  Map<String, dynamic> toJson() => {
    'issuer': issuer,
    'account': account,
    'secret': secret,
    'digits': digits,
    'period': period,
  };


  factory TokenModel.fromJson(Map<String, dynamic> json) => TokenModel(
    issuer: json['issuer'],
    account: json['account'],
    secret: json['secret'],
    digits: json['digits'],
    period: json['period'],
  );
}