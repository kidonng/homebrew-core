class Orientdb < Formula
  desc "Graph database"
  homepage "https://orientdb.org/"
  url "https://search.maven.org/remotecontent?filepath=com/orientechnologies/orientdb-community/3.2.32/orientdb-community-3.2.32.zip"
  sha256 "6bfad71532492d1349b571e25779cf78cb34bbcf4197781b5ad2452f9e5fd5e4"
  license "Apache-2.0"

  livecheck do
    url "https://orientdb.org/download"
    regex(/href=.*?orientdb(?:-community)?[._-]v?(\d+(?:\.\d+)+)\.zip/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_sonoma:   "a2a4881490ffbbaa3dd8c207e4836be7adb532672f488d896c5390efb251d893"
    sha256 cellar: :any_skip_relocation, arm64_ventura:  "a2a4881490ffbbaa3dd8c207e4836be7adb532672f488d896c5390efb251d893"
    sha256 cellar: :any_skip_relocation, arm64_monterey: "a2a4881490ffbbaa3dd8c207e4836be7adb532672f488d896c5390efb251d893"
    sha256 cellar: :any_skip_relocation, sonoma:         "a2a4881490ffbbaa3dd8c207e4836be7adb532672f488d896c5390efb251d893"
    sha256 cellar: :any_skip_relocation, ventura:        "a2a4881490ffbbaa3dd8c207e4836be7adb532672f488d896c5390efb251d893"
    sha256 cellar: :any_skip_relocation, monterey:       "a2a4881490ffbbaa3dd8c207e4836be7adb532672f488d896c5390efb251d893"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "4f8afe80cd3810472c8ebc377710a5a153f17779bd1041b40a6c902be49603c3"
  end

  depends_on "maven" => :build
  depends_on "openjdk"

  def install
    rm_r(Dir["bin/*.bat"])

    chmod 0755, Dir["bin/*"]
    libexec.install Dir["*"]

    inreplace "#{libexec}/config/orientdb-server-config.xml", "</properties>",
       <<~EOS
         <entry name="server.database.path" value="#{var}/db/orientdb" />
         </properties>
       EOS
    inreplace "#{libexec}/config/orientdb-server-log.properties", "../log", "#{var}/log/orientdb"
    inreplace "#{libexec}/bin/orientdb.sh", "../log", "#{var}/log/orientdb"
    inreplace "#{libexec}/bin/server.sh", "ORIENTDB_PID=$ORIENTDB_HOME/bin", "ORIENTDB_PID=#{var}/run/orientdb"
    inreplace "#{libexec}/bin/shutdown.sh", "ORIENTDB_PID=$ORIENTDB_HOME/bin", "ORIENTDB_PID=#{var}/run/orientdb"
    inreplace "#{libexec}/bin/orientdb.sh", '"YOUR_ORIENTDB_INSTALLATION_PATH"', libexec
    inreplace "#{libexec}/bin/orientdb.sh", 'su $ORIENTDB_USER -c "cd \"$ORIENTDB_DIR/bin\";', ""
    inreplace "#{libexec}/bin/orientdb.sh", '&"', "&"

    (bin/"orientdb").write_env_script "#{libexec}/bin/orientdb.sh", JAVA_HOME: Formula["openjdk"].opt_prefix
    (bin/"orientdb-console").write_env_script "#{libexec}/bin/console.sh", JAVA_HOME: Formula["openjdk"].opt_prefix
    (bin/"orientdb-gremlin").write_env_script "#{libexec}/bin/gremlin.sh", JAVA_HOME: Formula["openjdk"].opt_prefix
  end

  def post_install
    (var/"db/orientdb").mkpath
    (var/"run/orientdb").mkpath
    (var/"log/orientdb").mkpath
    touch "#{var}/log/orientdb/orientdb.err"
    touch "#{var}/log/orientdb/orientdb.log"

    ENV["ORIENTDB_ROOT_PASSWORD"] = "orientdb"
    system "#{bin}/orientdb", "stop"
    sleep 3
    system "#{bin}/orientdb", "start"
    sleep 3
  ensure
    system "#{bin}/orientdb", "stop"
  end

  def caveats
    <<~EOS
      The OrientDB root password was set to 'orientdb'. To reset it:
        https://orientdb.org/docs/3.1.x/security/Server-Security.html#restoring-the-servers-user-root
    EOS
  end

  service do
    run opt_libexec/"bin/server.sh"
    keep_alive true
    working_dir var
    log_path var/"log/orientdb/sout.log"
    error_log_path var/"log/orientdb/serror.log"
  end

  test do
    ENV["CONFIG_FILE"] = "#{testpath}/orientdb-server-config.xml"
    ENV["ORIENTDB_ROOT_PASSWORD"] = "orientdb"

    cp "#{libexec}/config/orientdb-server-config.xml", testpath
    inreplace "#{testpath}/orientdb-server-config.xml", "</properties>",
      "  <entry name=\"server.database.path\" value=\"#{testpath}\" />\n    </properties>"

    assert_match "OrientDB console v.#{version}", pipe_output("#{bin}/orientdb-console \"exit;\"")
  end
end
