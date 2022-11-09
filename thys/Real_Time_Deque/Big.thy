section \<open>Bigger End of Deque\<close>

theory Big
imports Common
begin

text \<open>\<^noindent> The bigger end of the deque during transformation can be in two phases:

 \<^descr> \<open>Reverse\<close>: Using the \<open>step\<close> function the originally contained elements, which will be kept in this end, are reversed.
 \<^descr> \<open>Common\<close>: Specified in theory \<open>Common\<close>. Is used to reverse the elements from the previous phase again to get them in the original order.

\<^noindent> Each phase contains a \<open>current\<close> state, which holds the original elements of the deque end. 
\<close>

datatype (plugins del: size) 'a state = 
     Reverse "'a current" "'a stack" "'a list" nat
   | Common "'a Common.state"

text \<open>\<^noindent> Functions:

\<^descr> \<open>push\<close>, \<open>pop\<close>: Add and remove elements using the \<open>current\<close> state.
\<^descr> \<open>step\<close>: Executes one step of the transformation\<close>

instantiation state ::(type) step
begin

fun step_state :: "'a state \<Rightarrow> 'a state" where
  "step (Common state) = Common (step state)"
| "step (Reverse current _ aux 0) = Common (normalize (Copy current aux [] 0))"
| "step (Reverse current big aux count) = 
     Reverse current (Stack.pop big) ((Stack.first big)#aux) (count - 1)"

instance..
end

fun push :: "'a \<Rightarrow> 'a state \<Rightarrow> 'a state" where
  "push x (Common state) = Common (Common.push x state)"
| "push x (Reverse current big aux count) = Reverse (Current.push x current) big aux count"

fun pop :: "'a state \<Rightarrow> 'a * 'a state" where
  "pop (Common state) = (let (x, state) = Common.pop state in (x, Common state))"
| "pop (Reverse current big aux count) = (first current, Reverse (drop_first current) big aux count)"

end