class ThuongHoc {
  const ThuongHoc({
    required this.xu,
    required this.chuoi,
    required this.daHocHomNay,
    required this.proDen,
    required this.pro,
    required this.gioiHanAi,
    required this.daDungAi,
    required this.thuong,
  });

  final int xu;
  final int chuoi;
  final bool daHocHomNay;
  final int proDen;
  final bool pro;
  final int gioiHanAi;
  final int daDungAi;
  final int thuong;

  factory ThuongHoc.tuMap(Map<String, dynamic> m) => ThuongHoc(
    xu: m['xu'] as int,
    chuoi: m['chuoi'] as int,
    daHocHomNay: m['daHocHomNay'] as bool,
    proDen: m['proDen'] as int,
    pro: m['pro'] as bool,
    gioiHanAi: m['gioiHanAi'] as int,
    daDungAi: m['daDungAi'] as int,
    thuong: m['thuong'] as int? ?? 0,
  );
}
