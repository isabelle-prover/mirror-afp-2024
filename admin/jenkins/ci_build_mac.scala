object profile extends isabelle.CI_Profile
{

  import isabelle._

  val afp = Path.explode("$ISABELLE_HOME/afp")
  val afp_thys = afp + Path.explode("thys")

  override def threads = 2
  override def jobs = 4
  def include = List(afp_thys)
  def select = Nil

  def pre_hook(args: List[String]) =
    println(s"Build for AFP id ${hg_id(afp)}")

  def post_hook(results: Build.Results) = {}

  def selection = Sessions.Selection(
    all_sessions = true,
    exclude_sessions = List("HOL-Proofs", "HOL-ODE-Numerics"),
    exclude_session_groups = List("slow"))

}
