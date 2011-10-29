require File.dirname(__FILE__) + '/test_helper'
require 'assert2/rjs'
require 'ostruct'
require 'action_controller'
require 'action_controller/test_process'


class AssertRjsSuite < Test::Unit::TestCase
  def setup
    @response = OpenStruct.new(:body => "Element.update(\"label_7\", \"<input checked=\\\"checked\\\" id=\\\"Top_Ranking\\\" name=\\\"Top_Ranking\\\" type=\\\"checkbox\\\" value=\\\"Y\\\" \\/>I want a pet &lt; than a chihuahua<input id=\\\"cross_sale_1\\\" name=\\\"cross_sale_1\\\" type=\\\"hidden\\\" value=\\\"7\\\" \\/>\");")
  end

  def test_assert_rjs_passes
    assert_rjs_ :replace_html, :label_7
    assert_rjs_ :replace_html, :label_7, /Top_Ranking/
    assert_rjs_ :replace_html, :label_7, /pet &lt; than a chihuahua/ # ERGO ouch!

    assert_rjs_ :replace_html, :label_7 do
      input.Top_Ranking! :type => :checkbox, :value => :Y
      input.cross_sale_1! :type => :hidden, :value => 7
    end
  end

  def test_assert_rjs_flunks
    assert_flunk /replace_html.for.ID.lay_belle_7.not.found.in .*
                       Top_Ranking/mx do
      assert_rjs_ :replace_html, :lay_belle_7
    end

    assert_flunk /replace_html.for.ID.label_7.has.incorrect.payload .*
                       Top_Ranking/mx do
      assert_rjs_ :replace_html, :label_7, /Toop_Roonking/
    end

    assert_flunk /replace_html.for.ID.label_7.has.incorrect.payload .*
                  Could.not.find.this.reference .*
                     Top_Ranking/mx do
      assert_rjs_ :replace_html, :label_7 do
        input.Top_Ranking! :type => :checkbox, :value => :Y
        input.cross_sale_1! :type => :hidden, :valyoo => 7
      end
    end
  end

  def test_assert_rjs_passes_js_in_its_first_argument
    source = @response.body
    @response = nil
    assert_rjs_ source, :replace_html, :label_7
    assert_rjs_ source, :replace_html, :label_7, /Top_Ranking/
    assert_rjs_ source, :replace_html, :label_7, /pet &lt; than a chihuahua/

    assert_rjs_ source, :replace_html, :label_7 do
      input.Top_Ranking! :type => :checkbox, :value => :Y
      input.cross_sale_1! :type => :hidden, :value => 7
    end
  end

  def test_assert_rjs_call_finds_arguments
    onclick = 'Element.toggle("account");; return false;'
    assert_rjs_ onclick, :call, 'Element.toggle', 'account'
  end  #  ERGO  blog about these three

  def test_assert_rjs_call_finds_arguments_fuzzily
    onclick = 'Element.toggle("account");; return false;'
    assert_rjs_ onclick, :call, 'Element.toggle', /count/
  end

  def test_assert_rjs_call_finds_arguments
    onclick = 'Element.toggle("account");; return false;'
    assert_rjs_ onclick, :toggle, 'account'
    assert_rjs_ onclick, :toggle, /count/
  end  #  ERGO  does the FauxController have a toggle to also test?

  def prop_node(json)
    @js = "foo(#{ json })"
    nodes = RKelly.parse(@js)
    foo = nodes.pointcut('foo()').matches.first
    return foo.grep(RKelly::Nodes::ArgumentsNode).first.value.first
  end

  def test_props_to_hash
    props = prop_node('{ bottom: "Stuff" }')
    rjs = AssertRjs::CALL.new(@js, :alert, self)
    assert{ rjs.props_to_hash(props.value).nil? }
    assert{ rjs.props_to_hash(props) == { :bottom => 'Stuff' } }
    hash = rjs.props_to_hash(props)
  end  #  TODO  move me out

  def test_hash_match
    props = prop_node('{ bottom: "Stuff" }')
    rjs = AssertRjs::CALL.new(@js, :alert, self)
    hash = rjs.props_to_hash(props)
    assert{ rjs.hash_match(hash, { :bottom => 'Stuff' }) }
    assert{ rjs.hash_match(hash, { :bottom => /Stuff/ }) }
    assert{ rjs.hash_match(hash, { :bottom => /Stu/   }) }
    deny{ rjs.hash_match(hash, { :bottom => /Stew/   }) }
    deny{ rjs.hash_match(hash, { :bottom => 'Stew'   }) }
    deny{ rjs.hash_match(hash, { :top => 'Stuff'  }) }
    assert{ rjs.hash_match(hash.merge(:also => 'whatever'),
                                 { :bottom => /Stuff/ }) }
  end  #  TODO  move me out

end


ActionController::Base.logger = nil
# ActionController::Base.ignore_missing_templates = false
ActionController::Routing::Routes.reload rescue nil

# faux controller & tests SHAMELESSLY ripped off from
# Rich Poirier's assert_rjs test code!
class FauxController < ActionController::Base  #  thanks, bra!
  def alert
    render :update do |page|
      page.alert 'This is an alert'
    end
  end

  def assign
    render :update do |page|
      page.assign 'a', '2'
    end
  end

  def call
    render :update do |page|
      page.call 'foo', 'bar', 'baz'
    end
  end

  def call_twice
    render :update do |page|
      page.call 'foo', 'blutto'
      page.call 'foo', 'bar', 'baz'
    end
  end

  def draggable
    render :update do |page|
      page.draggable 'my_image', :revert => true
    end
  end

  def drop_receiving
    render :update do |page|
      page.drop_receiving "my_cart", :url => { :controller => "cart", :action => "add" }
    end
  end

  def hide
    render :update do |page|
      page.hide 'some_div'
    end
  end

  def insert_html
    render :update do |page|
      page.insert_html :bottom, 'content', 'Stuff in the content div'
    end
  end

  def redirect
    render :update do |page|
      page.redirect_to :controller => 'sample', :action => 'index'
    end
  end

  def remove
    render :update do |page|
      page.remove 'offending_div'
    end
  end

  def replace
    render :update do |page|
      page.replace 'person_45', '<div>This replaces person_45</div>'
    end
  end

  def replace_html
    render :update do |page|
      page.replace_html 'person_45', '<div>This goes inside person_45'
    end
  end

  def show
    render :update do |page|
      page.show 'post_1', 'post_2', 'post_3'
    end
  end

  def sortable
    render :update do |page|
      page.sortable 'sortable_item'
    end
  end

  def toggle
    render :update do |page|
      page.toggle "post_1", "post_2", "post_3"
    end
  end

  def visual_effect
    render :update do |page|
      page.visual_effect :highlight, "posts", :duration => '1.0'
    end
  end

  def page_with_one_chained_method
    render :update do |page|
      page['some_id'].toggle
    end
  end

  def page_with_assignment
    render :update do |page|
      page['some_id'].style.color = 'red'
    end
  end

  def rescue_errors(e) raise e end

end


class FauxControllerSuite < ActionController::TestCase
  tests FauxController

  def test_assert_rjs_misses_its_response_body
     #  TODO  test that a missing response_body provides a good error
  end

  # ERGO add "interrupt-and-integrate" to autotask
  # TODO  test all their return values

  def test_alert
    get :alert
    rjs = AssertRjs::ALERT.new(@response.body, :alert, self)
    text = rjs.pwn 'This is an alert'
    assert{ text == 'This is an alert' }
    text = rjs.pwn 'This is not an alert'
    assert{ /not found in/ =~ rjs.failure_message }

    assert_rjs_ :alert, 'This is an alert'

#     assert_flunk /alert.with .*
#                   This.is.not.a.drill .*
#                   alert .* This.is.an.alert/mx do
#       assert_rjs_ :alert, 'This is not a drill'
#     end

    @response = OpenStruct.new(:body => 'negatory()')

#     assert_flunk /alert not found in.*negatory/m do
#       assert_rjs_ :alert, 'This is an alert'
#     end
  end


  def test_assign
    get :assign

#     assert_nothing_raised { assert_rjs_ :assign, 'a', '2' }
#     assert_flunk(/./)do
#       assert_rjs_ :assign, 'a', '3'
#     end
#
#     assert_nothing_raised { assert_no_rjs :assign, 'a', '3' }
#     assert_flunk(/./)do
#       assert_no_rjs :assign, 'a', '2'
#     end
  end

  def test_call
    get :call
    assert_rjs_ :call, 'foo', 'bar', 'baz'

    assert_flunk /foo .* not.found.in .*
                  foo\("bar",."baz"\)/mx do
      assert_rjs_ :call, 'foo', 'bar'
    end

    assert_flunk /frob .* not.found.in .*
                  foo\("bar",."baz"\)/mx do
      assert_rjs_ :call, :frob, :bar, :baz
    end

    assert_flunk /zap .* not.found.in .*
                  foo\("bar",."baz"\)/mx do
      assert_rjs_ :call, :foo, :bar, :zap
    end

    assert_nothing_raised{ assert_no_rjs_ :call, 'foo', 'bar' }

    assert_flunk /foo.*bar.*baz/ do
      assert_no_rjs_ :call, 'foo', 'bar', 'baz'
    end
  end

#  TODO  count all the assertions
#  TODO  permit explicit JS input: assert_javascript a[:onmouseover]
#  TODO  hook into outer assert_xhtml!

  def test_call_twice
    get :call_twice
    assert_rjs_ :call, 'foo', 'bar', 'baz'

    assert_flunk /foo .* not.found.in .*
                  foo\("bar",."baz"\)/mx do
      assert_rjs_ :call, 'foo', 'bar'
    end

    assert_flunk /frob.with.arguments .* bar .* baz .*
                  not.found.in .*
                  foo\("bar",."baz"\)/mx do
      assert_rjs_ :call, :frob, :bar, :baz
    end

    assert_flunk /zap .* not.found.in .*
                 foo\("bar",."baz"\)/mx do
      assert_rjs_ :call, :foo, :bar, :zap
    end

    assert_nothing_raised{ assert_no_rjs_ :call, 'foo', 'bar' }

    assert_flunk /baz/ do
      assert_no_rjs_ :call, 'foo', 'bar', 'baz'
    end
  end

  def test_draggable
    get :draggable

#     assert_nothing_raised { assert_rjs_ :draggable, 'my_image', :revert => true }
#     assert_flunk(/./)do
#       assert_rjs_ :draggable, 'not_my_image'
#     end
#
#     assert_nothing_raised { assert_no_rjs :draggable, 'not_my_image' }
#     assert_flunk(/./)do
#       assert_no_rjs :draggable, 'my_image', :revert => true
#     end
  end

  def test_remove
    get :remove

    assert_nothing_raised do
      assert_rjs_ :remove, 'offending_div'
      assert_no_rjs_ :remove, 'dancing_happy_div'
    end

    #  TODO  don't say "call call" in diagnostics

    assert_flunk /dancing.*not found/ do
      assert_rjs_ :remove, 'dancing_happy_div'
    end

    assert_flunk /should not find.*offending_div/ do
      assert_no_rjs_ :remove, 'offending_div'
    end
  end

  def test_insert_html_raw
    get :insert_html
    assert_rjs_ :call, 'Element.insert', :content, { :bottom => /Stuff/ }
  end

  def test_insert_html
    get :insert_html
    assert_rjs_ :insert_html, :bottom, :content, /Stuff/
      #  TODO  block notation already
  end

  def test_replace
    get :replace

    assert_nothing_raised do
      # No content matching
      assert_rjs_ :replace, 'person_45'
      # String content matching
      assert_rjs_ :replace, 'person_45', '<div>This replaces person_45</div>'
      # regexp content matching
      assert_rjs_ :replace, 'person_45', /<div>.*person_45.*<\/div>/
      # assert_xhtml
      assert_rjs_ :replace, 'person_45', /<div>.*person_45.*<\/div>/ do
        div /person_45/
      end

      assert_no_rjs_ :replace, 'person_45', '<div>This replaces person_46</div>'
      assert_no_rjs_ :replace, 'person_45', /person_46/

      assert_no_rjs_ :replace, 'person_45' do
        div 'This replaces person_46'
      end
    end

    assert_flunk(/should not find.*person_45/){ assert_no_rjs_ :replace, 'person_45' }
    assert_flunk(/45/){ assert_no_rjs_ :replace, 'person_45', /person_45/ }
    assert_flunk(/46/){ assert_rjs_ :replace, 'person_46' }
    assert_flunk(/40 Dollars/){ assert_rjs_ :replace, 'person_45', 'Ballad of 40 Dollars by Tom T. Hall' }
    assert_flunk(/./){ assert_rjs_ :replace, 'person_45', /you're always making things difficult/ }
    assert_flunk /Could not find this reference/ do
      assert_rjs_ :replace, 'person_45' do
        div{ strong{ 'person_42' } }
      end
    end
  end

#  TODO  grumble - count the assertions

  def test_whatever
    assert_flunk /whatever not implemented/ do
      assert_rjs_ :whatever
    end
  end

end

# "It's a big house this, and very peculiar.  Always a bit more to discover,
#  and no knowing what you'll find around a corner.  And Elves, sir!" --Samwise

# "Sam, would you please STFU??" --Frodo
