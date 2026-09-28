package foxlite.physics;

#if (physhx && cpp)
import foxlite.physics.FoxPhysicsBodyType;

/**
 * The basic interface for a PhysX actor.
 */
interface IFoxPhysXActor
{
	var bodyType:FoxPhysicsBodyType;
	function destroy():Void;
	function syncTransform():Void;
}
#end
