package foxlite.physics.kinematics;

#if (physhx && cpp)
import foxlite.physics.FoxPhysicsBodyType;
import openfl.geom.Vector3D;
import physx.PxCapsuleController;
import physx.PxController;
import physx.PxControllerFilters;
import physx.foundation.PxExtendedVec3;
import physx.foundation.PxVec3;

/**
 * A FoxObject paired with a PhysX capsule controller. This gives more control over
 * the controller's movement and physics behavior than a standard rigid body.
 *
 * This is great for situations like player movement, where you want to control
 * the player's movement and physics behavior rather than handing *everything* to
 * PhysX.
 *
 * There is actually a class that let's you control FoxKinematicControllers like
 * players, called `FoxDefaultPlayerController`. It's called default because it's basic,
 * and doesn't have many special features. I suggest you write your own for more flexibility/control.
 *
 * @see `FoxDefaultPlayerController`
 */
@:include("PxPhysicsAPI.h")
class FoxKinematicController implements IFoxPhysXActor
{
	/**
	 * The FoxObject this controller is paired with.
	 */
	public var foxObject:FoxObject;

	/**
	 * The PhysX capsule controller this controller uses.
	 */
	public var pxController:PxCapsuleController;

	/**
	 * The body type of this controller.
	 */
	public var bodyType:FoxPhysicsBodyType = FoxPhysicsBodyType.KINEMATIC;

	/**
	 * Raw collision flag bits from the last call to `move()`.
	 * Kept as a plain Int, read directly from the underlying C++ value,
	 * since unfortunately, PxControllerCollisionFlags/PxControllerCollisionFlag don't
	 * convert cleanly through hxcpp. -1 means "never moved yet".
	 *
	 * Bit values (from PxControllerCollisionFlag):
	 *   eCOLLISION_SIDES = 1 << 0
	 *   eCOLLISION_UP    = 1 << 1
	 *   eCOLLISION_DOWN  = 1 << 2
	 */
	public var lastCollisionFlags:Int = -1;

	@:dox(hide) private var filters:PxControllerFilters;

	/**
	 * Creates a new FoxKinematicController.
	 * @param foxObject - The FoxObject this controller is paired with.
	 * @param pxController - The PhysX capsule controller this controller uses.
	 */
	public function new(foxObject:FoxObject, pxController:PxCapsuleController)
	{
		this.foxObject = foxObject;
		this.pxController = pxController;
		this.filters = PxControllerFilters.create();
	}

	/**
	 * Moves the controller by a displacement vector this frame.
	 * @param disp - Displacement for this tick (i.e. velocity * dt, computed by your own logic)
	 * @param minDist - Minimum distance to bother moving. You can use a small epsilon (e.g. 0.0001)
	 * @param dt - Elapsed time for this tick.
	 * @return Raw collision flag bits (see `lastCollisionFlags` doc for bit layout).
	 * 
	 * @see `lastCollisionFlags`
	 */
	public function move(disp:Vector3D, minDist:Float, dt:Float):Int
	{
		var pxDisp = new PxVec3(disp.x, disp.y, disp.z);
		var raw:PxControllerCollisionFlags = pxController.move(pxDisp, minDist, dt, filters);
		/*
			Read the underlying bits directly as an unsigned char, bypassing
			the abstract's own from/to conversions, since they don't convert cleanly
			even though I did try to get it to work.
		 */
		var flags:Int = untyped __cpp__("(int)(unsigned char){0}", raw);
		lastCollisionFlags = flags;
		return flags;
	}

	public function isGrounded():Bool
	{
		if (lastCollisionFlags < 0)
			return false;
		return (lastCollisionFlags & (1 << 2)) != 0; // eCOLLISION_DOWN
	}

	public function isTouchingWall():Bool
	{
		if (lastCollisionFlags < 0)
			return false;
		return (lastCollisionFlags & (1 << 0)) != 0; // eCOLLISION_SIDES
	}

	public function isTouchingCeiling():Bool
	{
		if (lastCollisionFlags < 0)
			return false;
		return (lastCollisionFlags & (1 << 1)) != 0; // eCOLLISION_UP
	}

	/**
	 * Syncs the FoxObject's position with the controller's position.
	 */
	public function syncTransform()
	{
		if (foxObject == null)
			return;
		var pos:PxExtendedVec3 = pxController.getPosition();
		foxObject.setPosition(pos.x, pos.y, pos.z);
	}

	/**
	 * Sets the controller's position and teleports it.
	 * @param v - The new position.
	 */
	public function setPosition(v:Vector3D)
	{
		pxController.setPosition(new PxExtendedVec3(v.x, v.y, v.z));
	}

	/**
	 * Gets the controller's current position.
	 * @return `Vector3D`
	 */
	public function getPosition():Vector3D
	{
		var pos = pxController.getPosition();
		return new Vector3D(pos.x, pos.y, pos.z);
	}

	/**
	 * Destroys this controller.
	 */
	public function destroy()
	{
		if (pxController != null)
		{
			pxController.release();
			pxController = null;
		}
		foxObject = null;
	}
}
#end
