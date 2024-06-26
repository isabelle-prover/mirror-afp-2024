/* Author: Fabian Huch, TU Muenchen

AFP Hugo wrapper and project layout.
 */
package afp


import isabelle.*


object Hugo {
  val hugo_home = Isabelle_System.getenv("ISABELLE_HUGO")
  val hugo_static = Path.explode("$AFP_BASE") + Path.make(List("admin", "site"))

  class Layout private(private[Hugo] val src_dir: Path) {
    private def write(file: Path, content: String): Unit = {
      val path = src_dir + file
      if (!path.dir.file.exists()) path.dir.file.mkdirs()
      File.write(path, content)
    }

    val data_dir = src_dir + Path.basic("data")

    private def format(json: JSON.T): String = {
      json match {
        case elems: List[_] => elems.map(format).mkString("[", ",\n", "]")
        case JSON.Object(m) => m.map { case (k,v) => format(k) + ": " + format(v) }.mkString("{", ",\n", "}")
        case _ => isabelle.JSON.Format(json)
      }
    }

    def write_data(file: Path, content: JSON.T): Unit =
      write(Path.basic("data") + file, format(content))

    val content_dir = src_dir + Path.basic("content")

    def write_content(file: Path, content: JSON.T): Unit =
      write(Path.basic("content") + file, format(content))

    val static_dir = src_dir + Path.basic("static")
    
    def write_static(file: Path, content: JSON.T): Unit =
      write(Path.basic("static") + file, format(content))

    private val generated_dirs = List(
      List("content", "entries"),
      List("content", "theories"),
      List("data"),
      List("resources"),
      List("static")).map(Path.make)

    val cache_dir = src_dir + Path.basic("cache")

    def write_cache(file: Path, content: JSON.T): Unit =
      write(Path.basic("cache") + file, format(content))

    /* Static project files */

    private val project_files = List(
      List("content", "webapp"),
      List("content", "_index.md"),
      List("content", "about.md"),
      List("content", "submission.md"),
      List("content", "download.md"),
      List("content", "help.md"),
      List("content", "search.md"),
      List("content", "statistics.md"),
      List("content", "submission.md"),
      List("themes"),
      List("config.json")).map(Path.make)

    private val is_static_src = hugo_static.canonical.absolute == src_dir.canonical.absolute

    def copy_project(): Unit = {
      if (!is_static_src) project_files.foreach(file =>
        Isabelle_System.copy_dir(hugo_static + file, src_dir + file))
    }

    def clean(): Unit = {
      generated_dirs.foreach(file => Isabelle_System.rm_tree(src_dir + file))
      if (!is_static_src) project_files.foreach(file => Isabelle_System.rm_tree(src_dir + file))
    }
  }

  object Layout {
    def apply(src_dir: Path = Path.explode("$AFP_BASE") + Path.make(List("web", "hugo"))): Layout =
      new Layout(src_dir.canonical)
  }

  private lazy val exec =
    Path.explode(proper_string(hugo_home).getOrElse(error("No hugo component found"))) + Path.basic("hugo")

  private def source_specifier(layout: Layout, out_dir: Path): String =
    " -s " + quote(layout.src_dir.implode) + " -d " + quote(out_dir.canonical.implode)

  private def build_example(layout: Layout, out_dir: Path): Unit = {
    val env = Isabelle_System.settings(List("HUGO_IGNOREFILES" -> "[]"))
    Isabelle_System.bash(exec.implode + source_specifier(layout, out_dir: Path), env = env).check
  }

  def build(layout: Layout, out_dir: Path): Unit = {
    build_example(layout, out_dir)
    Isabelle_System.bash(exec.implode + source_specifier(layout, out_dir)).check
  }

  def watch(layout: Layout, out_dir: Path, progress: Progress = new Progress()): Unit = {
    build_example(layout, out_dir)
    Isabelle_System.bash(
      exec.implode + " server " + source_specifier(layout, out_dir),
      progress_stdout = progress.echo(_),
      progress_stderr = progress.echo_warning(_)).check
  }

  def clean(out_dir: Path): Unit =
    File.read_dir(out_dir).foreach(file => Isabelle_System.rm_tree(out_dir + Path.basic(file)))
}