const ngayMs = 86_400_000;
const muiGio = 7 * 3_600_000;

export function ngayVietNam(thoiDiem) {
  const moc = Math.floor((thoiDiem.getTime() + muiGio) / ngayMs);
  return {
    ngay: new Date(moc * ngayMs).toISOString().slice(0, 10),
    ngayTruoc: new Date((moc - 1) * ngayMs).toISOString().slice(0, 10),
    resetAt: new Date((moc + 1) * ngayMs - muiGio).toISOString(),
  };
}
