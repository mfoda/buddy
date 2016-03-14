package buddy.internal;
#if macro
import haxe.macro.Compiler;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.Context;

using haxe.macro.ExprTools;

class SuiteBuilder
{
	private static function injectAsync(e : Expr)
	{
		switch(e.expr) {
			// Fix autocomplete for should without parenthesis
			case EDisplay(e2, isCall): switch e2 {
				case macro $a.should:
					var change = macro $a.should();
					e2.expr = change.expr;

				case _:
			}

			// Fix fail calls, so PosInfos works.
			// Skip calls to fail, they will work
			case ECall({expr: EConst(CIdent("fail")), pos: _}, params):
				return;
				
			// Callbacks however, have to be wrapped.
			case EConst(CIdent("fail")):
				var change = macro function(?err : Dynamic) fail(err);
				e.expr = change.expr;
				return;

			case _:
		}
		
		switch(e) {
				
			case macro $a.should().$b, macro $a.should.$b:
				// Need to use untyped here for some unknown macro reason...
				var change = macro $a.should().$b;
				e.expr = change.expr;

			///// Describe

			case macro describe($s, function($n) $f):
				var change = macro describe($s, buddy.BuddySuite.TestFunc.Async(function($n) $f));
				e.expr = change.expr;
				f.iter(injectAsync);

			case macro describe($s, function() $f), macro describe($s, $f):
				var change = macro describe($s, buddy.BuddySuite.TestFunc.Sync(function() $f));
				e.expr = change.expr;
				f.iter(injectAsync);

			case macro xdescribe($s, function() $f), macro xdescribe($s, $f), macro @exclude describe($s, $f):
				var change = macro xdescribe($s, buddy.BuddySuite.TestFunc.Sync(function() $f));
				e.expr = change.expr;
				f.iter(injectAsync);

			///// BeforeEach/AfterEach

			// TODO: Deprecate before/after

			case macro before(function($n) $f):
				var change = macro @:pos(e.pos) before(buddy.BuddySuite.TestFunc.Async(function($n) $f));
				e.expr = change.expr;
				f.iter(injectAsync);

			case macro beforeEach(function($n) $f):
				var change = macro beforeEach(buddy.BuddySuite.TestFunc.Async(function($n) $f));
				e.expr = change.expr;
				f.iter(injectAsync);

			case macro before(function() $f), macro before($f):
				var change = macro @:pos(e.pos) before(buddy.BuddySuite.TestFunc.Sync(function() $f));
				e.expr = change.expr;
				f.iter(injectAsync);

			case macro beforeEach(function() $f), macro beforeEach($f):
				var change = macro beforeEach(buddy.BuddySuite.TestFunc.Sync(function() $f));
				e.expr = change.expr;
				f.iter(injectAsync);

			case macro after(function($n) $f):
				var change = macro @:pos(e.pos) after(buddy.BuddySuite.TestFunc.Async(function($n) $f));
				e.expr = change.expr;
				f.iter(injectAsync);

			case macro afterEach(function($n) $f):
				var change = macro afterEach(buddy.BuddySuite.TestFunc.Async(function($n) $f));
				e.expr = change.expr;
				f.iter(injectAsync);
				
			case macro after(function() $f), macro after($f):
				var change = macro @:pos(e.pos) after(buddy.BuddySuite.TestFunc.Sync(function() $f));
				e.expr = change.expr;
				f.iter(injectAsync);

			case macro afterEach(function() $f), macro afterEach($f):
				var change = macro afterEach(buddy.BuddySuite.TestFunc.Sync(function() $f));
				e.expr = change.expr;
				f.iter(injectAsync);

			///// BeforeAll/AfterAll

			case macro beforeAll(function($n) $f):
				var change = macro beforeAll(buddy.BuddySuite.TestFunc.Async(function($n) $f));
				e.expr = change.expr;
				f.iter(injectAsync);

			case macro beforeAll(function() $f), macro beforeAll($f):
				var change = macro beforeAll(buddy.BuddySuite.TestFunc.Sync(function() $f));
				e.expr = change.expr;
				f.iter(injectAsync);

			case macro afterAll(function($n) $f):
				var change = macro afterAll(buddy.BuddySuite.TestFunc.Async(function($n) $f));
				e.expr = change.expr;
				f.iter(injectAsync);

			case macro afterAll(function() $f), macro afterAll($f):
				var change = macro afterAll(buddy.BuddySuite.TestFunc.Sync(function() $f));
				e.expr = change.expr;
				f.iter(injectAsync);			
				
			///// It

			case macro it($s), macro it($s, {}), macro it($s, function() {}):
				var change = macro xit($s, null);
				e.expr = change.expr;

			case macro it($s, function($n) $f):
				var change = macro it($s, buddy.BuddySuite.TestFunc.Async(function($n) $f));
				e.expr = change.expr;
				f.iter(injectAsync);
				
			case macro it($s, function() $f), macro it($s, $f):
				var change = macro it($s, buddy.BuddySuite.TestFunc.Sync(function() $f));
				e.expr = change.expr;
				f.iter(injectAsync);

			case macro xit($s, function($n) $f):
				var change = macro xit($s, null);
				e.expr = change.expr;
				f.iter(injectAsync);
			
			case macro xit($s, function() $f), macro xit($s, $f), macro @exclude it($s, $f):
				var change = macro xit($s, null);
				e.expr = change.expr;
				f.iter(injectAsync);

			/////

			case _: e.iter(injectAsync);
		}
	}

	macro public static function build() : Array<Field>
	{
		var exists = false;
		var cls = Context.getLocalClass();
		if (cls == null || cls.get().superClass == null) return null;

		var fields = Context.getBuildFields();
		for (f in fields) if(f.name == "new") {
			switch f.kind {
				case FFun(f):
					switch(f.expr.expr)	{
						case EBlock(exprs):
							for (e in exprs) switch e {
								case macro super():	
									exists = true;
									break;
								case _:
							}

							if(!exists) exprs.unshift(macro super());

						case _:
					}
					f.expr.iter(injectAsync);

				case _:
			}
		}

		return fields;
	}
}
#end
