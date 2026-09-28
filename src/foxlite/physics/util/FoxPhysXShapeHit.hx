package foxlite.physics.util;

#if (physhx && cpp)
import openfl.geom.Vector3D;

/**
 * The hit report callback for a PhysX kinematic controller.
 */
typedef FoxPhysXShapeHit =
{
	/**
	 * The world position of the hit.
	 */
	var worldPos:Vector3D;

	/**
	 * The world normal of the hit.
	 */
	var worldNormal:Vector3D;

	/**
	 * The length of the hit.
	 */
	var length:Float;

	/**
	 * The actor that was hit.
	 */
	var actor:FoxPhysXBody;
}
#end
