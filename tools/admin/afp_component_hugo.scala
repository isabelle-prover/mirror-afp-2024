/* Author: Fabian Huch, TU Muenchen

Build Isabelle component for hugo site generator. See also:

  - https://gohugo.io
  - https://github.com/gohugoio/hugo
 */

package afp


import isabelle._


object AFP_Component_Hugo {
  /* platform information */

  sealed case class Download_Platform(platform_name: String, url_template: String) {
    override def toString: String = platform_name

    def is_windows: Boolean = url_template.contains("windows")
    def url(base_url: String, version: String): String =
      base_url + "/v" + version + "/" + url_template.replace("{V}", version)
  }

  val platforms: List[Download_Platform] =
    List(
      Download_Platform("arm64-darwin", "hugo_extended_{V}_darwin-universal.tar.gz"),
      Download_Platform("arm64-linux", "hugo_extended_{V}_linux-arm64.tar.gz"),
      Download_Platform("x86_64-darwin", "hugo_extended_{V}_darwin-universal.tar.gz"),
      Download_Platform("x86_64-linux", "hugo_extended_{V}_linux-amd64.tar.gz"),
      Download_Platform("x86_64-windows", "hugo_extended_{V}_windows-amd64.zip"))


  /* build hugo */

  val default_url = "https://github.com/gohugoio/hugo/releases/download"
  val default_version = "0.119.0"

  def build_hugo(
    base_url: String = default_url,
    version: String = default_version,
    target_dir: Path = Path.current,
    progress: Progress = new Progress
  ): Unit = {
    /* component */

    val component = "hugo-" + version
    val component_dir =
      Components.Directory(target_dir + Path.basic(component)).create(progress = progress)


    /* download */

    for (platform <- platforms) {
      val platform_dir =
        Isabelle_System.make_directory(component_dir.path + Path.basic(platform.platform_name))

      val url = platform.url(base_url, version)
      val name = Library.take_suffix(_ != '/', url.toList)._2.mkString

      val exe = Path.basic("hugo").exe_if(platform.is_windows)

      Isabelle_System.with_tmp_dir("download", component_dir.path.file) { download_dir =>
        Isabelle_System.with_tmp_dir("tmp", component_dir.path.file) { tmp_dir =>
          val archive_file = download_dir + Path.basic(name)

          Isabelle_System.download_file(url, archive_file, progress = progress)
          Isabelle_System.extract(archive_file, tmp_dir)
          Isabelle_System.move_file(tmp_dir + exe, platform_dir)
          Isabelle_System.move_file(tmp_dir + Path.basic("LICENSE"), component_dir.LICENSE)
          File.set_executable(platform_dir + exe)
        }
      }
    }


    /* settings */

    component_dir.write_settings("""
ISABELLE_HUGO="$COMPONENT/${ISABELLE_WINDOWS_PLATFORM64:-${ISABELLE_APPLE_PLATFORM64:-$ISABELLE_PLATFORM64}}"
""")


    /* README */

    File.write(component_dir.README,
      """This Isabelle components provides a hugo extended """ + version + """.

See also https://gohugo.io and executables from """ + base_url + """

        Fabian
        """ + Date.Format.date(Date.now()) + "\n")
  }

  val isabelle_tool =
    Isabelle_Tool("afp_component_hugo", "build afp hugo component", Scala_Project.here,
      { args =>
        var target_dir = Path.current
        var base_url = default_url
        var version = default_version

        val getopts = Getopts("""
Usage: isabelle afp_component_hugo [OPTIONS]

  Options are:
    -D DIR       target directory (default ".")
    -U URL       download URL (default: """" + default_url + """")
    -V VERSION   version (default: """" + default_version + """")

  Build extended hugo component.
    """,
          "D:" -> (arg => target_dir = Path.explode(arg)),
          "U:" -> (arg => base_url = arg),
          "V:" -> (arg => version = arg))

        val more_args = getopts(args)
        if (more_args.nonEmpty) getopts.usage()

        val progress = new Console_Progress()

        build_hugo(base_url = base_url, version = version, target_dir = target_dir,
          progress = progress)
    })
}