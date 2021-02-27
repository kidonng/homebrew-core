class ShadowsocksRust < Formula
  desc "Rust port of Shadowsocks"
  homepage "https://github.com/shadowsocks/shadowsocks-rust"
  url "https://github.com/shadowsocks/shadowsocks-rust/archive/v1.9.1.tar.gz"
  sha256 "2ce1468597e632ee8a280630be56e97ee7bf6f100990eaf84d9f0ef984bd3771"
  license "MIT"
  head "https://github.com/shadowsocks/shadowsocks-rust.git"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    server_port = free_port
    local_port = free_port

    (testpath/"shadowsocks-rust.json").write <<~EOS
      {
          "server":"127.0.0.1",
          "server_port":#{server_port},
          "local":"127.0.0.1",
          "local_port":#{local_port},
          "password":"test",
          "timeout":600,
          "method":null
      }
    EOS
    fork { exec bin/"ssserver", "-c", testpath/"shadowsocks-rust.json" }
    fork { exec bin/"sslocal", "-c", testpath/"shadowsocks-rust.json" }
    sleep 3

    output = shell_output "curl --socks5 127.0.0.1:#{local_port} https://github.com"
    assert_match "Where the world builds software", output
  end
end
