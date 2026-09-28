package foxlite.physics.kinematics;

#if (physhx && cpp)
import cpp.Pointer;
import cpp.Void as CppVoid;
import foxlite.physics.util.FoxPhysXShapeHit;
import openfl.geom.Vector3D;
import physx.PxCapsuleController;
import physx.PxControllerManager;
import physx.PxMaterial;
import physx.foundation.PxExtendedVec3;

/**
 * Builds a PxCapsuleControllerDesc with sensible defaults and creates the controller via the given manager.
 */
@:headerCode('
#ifndef HX_CONTROLLER_HIT_REPORT_H
#define HX_CONTROLLER_HIT_REPORT_H
#include <hxcpp.h>
#include "characterkinematic/PxController.h"

class HxControllerHitReport : public physx::PxUserControllerHitReport
{
public:
    Dynamic onShapeHitCb;
    Dynamic onControllerHitCb;
    Dynamic onObstacleHitCb;

    HxControllerHitReport() : onShapeHitCb(null()), onControllerHitCb(null()), onObstacleHitCb(null()) {}

    virtual void onShapeHit(const physx::PxControllerShapeHit& hit) override
    {
        if (onShapeHitCb.mPtr != 0) // Passing in the PxControllerShapeHit wouldnt work unfortunately.
            onShapeHitCb(
                (double)hit.worldPos.x, (double)hit.worldPos.y, (double)hit.worldPos.z,
                (double)hit.worldNormal.x, (double)hit.worldNormal.y, (double)hit.worldNormal.z,
                (double)hit.length,
                (int)(intptr_t)hit.actor
            );
    }

    // TODO: implement
    virtual void onControllerHit(const physx::PxControllersHit& hit) override
    {
        if (onControllerHitCb.mPtr != 0)
            onControllerHitCb();
    }

    // TODO: implement
    virtual void onObstacleHit(const physx::PxControllerObstacleHit& hit) override
    {
        if (onObstacleHitCb.mPtr != 0)
            onObstacleHitCb();
    }
};
#endif
')
@:include("PxPhysicsAPI.h")
class FoxKinematicControllerFactory
{
	/**
	 * Creates a PxCapsuleController.
	 * @param manager - The manager to create the controller with.
	 * @param material - The material to use for the controller.
	 * @param radius - The radius of the capsule.
	 * @param height - The height of the capsule.
	 * @param position - The initial position of the controller.
	 * @param hitReport - Optional hit report callback, fired when the CCT hits shapes/controllers/obstacles.
	 * This will not be applied if the world parameter is null.
	 * @param world - The world that the capsule controller will belong to.
	 * @return `PxCapsuleController`
	 */
	public static function createCapsule(manager:PxControllerManager, material:PxMaterial, radius:Float = 0.5, height:Float = 1.8, position:Vector3D = null,
			hitReport:FoxPhysXShapeHit->Void = null, world:FoxPhysXWorld = null):PxCapsuleController
	{
		var hitReportPtr:Pointer<CppVoid> = null;

		// This was so annoying..
		if (hitReport != null && world != null)
		{
			hitReportPtr = untyped __cpp__('::cpp::Pointer<void>(new HxControllerHitReport())');
			var cb:Dynamic = (wx:Float, wy:Float, wz:Float, nx:Float, ny:Float, nz:Float, length:Float, actorPtr:Int) ->
			{
				hitReport({
					worldPos: new Vector3D(wx, wy, wz),
					worldNormal: new Vector3D(nx, ny, nz),
					length: length,
					actor: world.getBodyFromPtr(actorPtr)
				});
			}
			untyped __cpp__('reinterpret_cast<HxControllerHitReport*>({0}.get_raw())->onShapeHitCb = {1}', hitReportPtr, cb);
		}

		var desc:PxCapsuleControllerDesc = PxCapsuleControllerDesc.create();

		desc.radius = radius;
		desc.height = height;
		desc.material = material;
		if (position != null)
			desc.position = new PxExtendedVec3(position.x, position.y, position.z);
		if (hitReportPtr != null && hitReportPtr.get_raw() != null)
			untyped __cpp__('reinterpret_cast<physx::PxCapsuleControllerDesc*>(&{0})->reportCallback = reinterpret_cast<physx::PxUserControllerHitReport*>({1}.get_raw())',
				desc, hitReportPtr);

		if (!desc.isValid())
			throw '[FoxLite > FoxKinematicControllerFactory]: Invalid PxCapsuleControllerDesc.';

		var controller:PxCapsuleController = untyped __cpp__('
            static_cast<physx::PxCapsuleController*>(
                ((physx::PxControllerManager*)(void*){0})->createController(
                    reinterpret_cast<physx::PxCapsuleControllerDesc&>({1})
                )
            )
        ', manager, desc);

		if (controller == null)
			throw '[FoxLite > FoxKinematicControllerFactory]: createController() returned null.';

		return cast controller;
	}
}
#end
