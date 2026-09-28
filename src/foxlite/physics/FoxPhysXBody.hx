package foxlite.physics;

#if (physhx && cpp)
import foxlite.physics.FoxPhysicsBodyType;
import openfl.geom.Vector3D;
import physx.PxRigidActor;
import physx.PxRigidDynamic;
import physx.foundation.PxTransform;
import physx.foundation.PxVec3;

/**
 * A FoxObject paired with a PhysX rigid body.
 */
@:include("PxPhysicsAPI.h")
class FoxPhysXBody implements IFoxPhysXActor
{
	/**
	 * Whether to destroy the FoxObject when this body is destroyed.
	 */
	public var destroyObjectOnDestroy:Bool = true;

	/**
	 * The FoxObject this body is paired with.
	 */
	public var foxObject:FoxObject;

	/**
	 * The PhysX actor this body is paired with.
	 */
	public var pxActor:PxRigidActor;

	/**
	 * The body type of this body. Either `DYNAMIC` or `STATIC`.
	 */
	public var bodyType:FoxPhysicsBodyType;

	/**
	 * Creates a new FoxPhysXBody.
	 * @param foxObject - The FoxObject this body is paired with.
	 * @param pxActor - The PhysX actor this body is paired with.
	 * @param isDynamic - Whether this body is dynamic or static.
	 */
	public function new(foxObject:FoxObject, pxActor:PxRigidActor, isDynamic:Bool = false)
	{
		this.foxObject = foxObject;
		this.pxActor = pxActor;
		bodyType = isDynamic ? FoxPhysicsBodyType.DYNAMIC : FoxPhysicsBodyType.STATIC;
	}

	/**
	 * Copies the PhysX actor's current transform into the FoxObject of this FoxPhysXBody.
	 */
	public function syncTransform()
	{
		if (foxObject == null || pxActor == null)
			return;
		var pose:PxTransform = pxActor.getGlobalPose();
		foxObject.setPosition(pose.p.x, pose.p.y, pose.p.z); // line 30!!
		foxObject.setRotationQuaternion(pose.q.x, pose.q.y, pose.q.z, pose.q.w);
	}

	/**
	 * Copies the actor's current linear velocity into a new Vector3D.
	 * ***This only works for dynamic actors. This returns null for static actors.***
	 * @return `Vector3D`
	 */
	public function getLinearVelocity():Vector3D
	{
		if (pxActor == null || bodyType != FoxPhysicsBodyType.DYNAMIC)
			return null;
		var pxVec3:PxVec3 = (cast pxActor : PxRigidDynamic).getLinearVelocity();
		return new Vector3D(pxVec3.x, pxVec3.y, pxVec3.z);
	}

	/**
	 * Assigns a new linear velocity to the actor.
	 * ***This only works for dynamic actors.***
	 * @param v - The new linear velocity.
	 * @param autowake - Whether to wake the object if it is dynamic.
	 */
	public function setLinearVelocity(v:Vector3D, autowake:Bool = true)
	{
		if (pxActor == null || bodyType != FoxPhysicsBodyType.DYNAMIC)
			return;
		var pxVec3:PxVec3 = new PxVec3(v.x, v.y, v.z);
		(cast pxActor : PxRigidDynamic).setLinearVelocity(pxVec3, autowake);
	}

	/**
	 * Returns the actor's current position. If the actor is null, returns null.
	 * @return Vector3D
	 */
	public function getPosition():Vector3D
	{
		if (pxActor == null)
			return null;
		var pose:PxTransform = pxActor.getGlobalPose();
		return new Vector3D(pose.p.x, pose.p.y, pose.p.z);
	}

	/**
	 * Assigns a new position to the actor. If the actor is null, does nothing.
	 * @param v - The new position.
	 */
	public function setPosition(v:Vector3D)
	{
		if (pxActor == null)
			return;
		var pxVec3:PxVec3 = new PxVec3(v.x, v.y, v.z);
		var pose = pxActor.getGlobalPose();
		pose.p = pxVec3;
		pxActor.setGlobalPose(pose);
	}

	/**
	 * Destroys this FoxPhysXBody. If `destroyObjectOnDestroy` is true, the FoxObject will also be destroyed.
	 */
	public function destroy()
	{
		if (pxActor != null)
		{
			pxActor.release();
			pxActor = null;
		}
		if (destroyObjectOnDestroy && foxObject != null)
			foxObject.destroy();
		foxObject = null;
	}
}
#end
