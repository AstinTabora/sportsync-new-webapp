export default function Logo({ size = 32 }: { size?: number }) {
  return (
    <img
      src="/images/sportsync_logo.png"
      alt="SportSync"
      width={size}
      height={size}
      className="object-contain"
      style={{ width: size, height: size }}
    />
  );
}
