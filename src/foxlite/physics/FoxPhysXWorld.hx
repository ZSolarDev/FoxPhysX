package foxlite.physics;

#if (physhx && cpp)
import foxlite.physics.FoxPhysicsWorldBase;
import physx.PxControllerManager;
import physx.PxFoundation;
import physx.PxPhysics;
import physx.PxPhysicsVersion;
import physx.PxScene;
import physx.PxSceneDesc;
import physx.common.PxTolerancesScale;
import physx.extensions.PxDefaultAllocator;
import physx.extensions.PxDefaultCpuDispatcher;
import physx.extensions.PxDefaultErrorCallback;
import physx.extensions.PxDefaultSimulationFilterShader;
import physx.foundation.PxVec3;
#if FPX_PVD
import physx.pvd.PxPvd;
import physx.pvd.PxPvdTransport;
#end

/**
 * A PhysX physics world.
 */
@:include("PxPhysicsAPI.h")
class FoxPhysXWorld extends FoxPhysicsWorldBase
{
	/**
	 * The actors in this world. Modify this list with `add` and `remove`.
	 * 
	 * @see add()
	 * @see remove()
	 */
	public var actors:Array<IFoxPhysXActor> = [];

	/**
	 * Whether to destroy all actors in this world when this world is destroyed.
	 */
	public var destroyActorsOnDestroy:Bool = true;

	/**
	 * The PhysX foundation instance.
	 */
	public var pxFoundation(default, null):PxFoundation;

	/**
	 * The PhysX physics instance.
	 */
	public var pxPhysics(default, null):PxPhysics;

	/**
	 * The PhysX scene instance.
	 */
	public var pxScene(default, null):PxScene;

	/**
	 * The PhysX controller manager instance.
	 */
	public var pxControllerMgr(default, null):PxControllerManager;

	#if FPX_PVD
	/**
	 * The PhysX Visual Debugger instance. Only available if FPX_PVD is defined.
	 */
	public var pxPvd(default, null):PxPvd;
	#end

	@:dox(hide) private var actorMap:Map<Int, FoxPhysXBody> = [];
	@:dox(hide) private var dispatcher:PxDefaultCpuDispatcher;

	@:dox(hide) private static var allocator:PxDefaultAllocator = null;
	@:dox(hide) private static var errorCallback:PxDefaultErrorCallback = null;

	/**
	 * Creates a new physics world. To use it in a `FoxScene`, you can
	 * simply assign it's physicsWorld property:
	 * 
	 * ```haxe
	 * scene.physicsWorld = new FoxPhysXWorld();
	 * ```
	 */
	public function new()
	{
		super();

		pxFoundation = PxFoundation.create(PX_PHYSICS_VERSION, allocator, errorCallback);
		if (pxFoundation == null)
			throw '[FoxLite > FoxPhysXWorld]: Failed to initialize the PhysX foundation instance.';

		#if FPX_PVD
		pxPvd = PxPvd.create(pxFoundation);
		if (pxPvd != null)
		{
			var transport = PxPvdTransport.defaultPvdSocketTransportCreate("localhost", 5425, 10);
			pxPvd.connect(transport, eALL);
			trace('[FoxLite > FoxPhysXWorld]: PhysX PVD initialized.');
		}
		else
			throw '[FoxLite > FoxPhysXWorld]: Failed to initialize the PhysX PVD instance. Skipping.';
		#end

		var scale = new PxTolerancesScale();
		pxPhysics = PxPhysics.create(PX_PHYSICS_VERSION, pxFoundation, scale #if FPX_PVD, true, pxPvd #end);
		if (pxPhysics == null)
			throw '[FoxLite > FoxPhysXWorld]: Failed to initialize the PhysX physics instance.';

		var sceneDesc = new PxSceneDesc(pxPhysics.getTolerancesScale());
		sceneDesc.gravity = new PxVec3(0, -9.81, 0);

		dispatcher = PxDefaultCpuDispatcher.create(0);
		sceneDesc.cpuDispatcher = dispatcher;
		sceneDesc.filterShader = PxDefaultSimulationFilterShader.func;

		pxScene = pxPhysics.createScene(sceneDesc);
		if (pxScene == null)
			throw '[FoxLite > FoxPhysXWorld]: Failed to initialize the PhysX scene instance.';

		#if FPX_PVD
		var pvdClient = pxScene.getScenePvdClient();
		if (pvdClient != null)
		{
			pvdClient.setScenePvdFlag(eTRANSMIT_CONSTRAINTS, true);
			pvdClient.setScenePvdFlag(eTRANSMIT_CONTACTS, true);
			pvdClient.setScenePvdFlag(eTRANSMIT_SCENEQUERIES, true);
		}
		#end

		pxControllerMgr = PxCreateControllerManager(pxScene);
		if (pxControllerMgr == null)
			throw '[FoxLite > FoxPhysXWorld]: Failed to create the controller manager instance.';
	}

	/**
	 * Adds an actor to this world.
	 * @param actor - The actor to add.
	 * @return `IFoxPhysXActor` - The actor that was added, for chaining.
	 */
	public function add(actor:IFoxPhysXActor):IFoxPhysXActor
	{
		actors.push(actor);

		if (actor is FoxPhysXBody)
		{
			var body = (cast actor : FoxPhysXBody);
			pxScene.addActor(body.pxActor);
			actorMap.set(getPtrFromBody(body), body);
		}
		return actor;
	}

	/**
	 * Removes an actor from this world.
	 * @param actor - The actor to remove.
	 * @return `IFoxPhysXActor` - The actor that was removed, for chaining.
	 */
	public function remove(actor:IFoxPhysXActor):IFoxPhysXActor
	{
		actors.remove(actor);
		if (Std.isOfType(actor, FoxPhysXBody))
			pxScene.removeActor(cast(actor, FoxPhysXBody).pxActor);
		return actor;
	}

	/**
	 * Gets the pointer to a body. Used internally for identification on controller
	 * actor hit callbacks.
	 * @param body - The body to get the pointer from.
	 * @return `Int` - The pointer to the body.
	 */
	public function getPtrFromBody(body:FoxPhysXBody):Int
		return untyped __cpp__('(int)(intptr_t){0}.get_raw()', body.pxActor);

	/**
	 * Gets a body from a pointer to the body. Used internally for identification on controller
	 * actor hit callbacks.
	 * @param ptr - The pointer to the body.
	 * @return `FoxPhysXBody` - The body, or null if not found.
	 */
	public function getBodyFromPtr(ptr:Int):FoxPhysXBody
		return actorMap[ptr];

	@:dox(hide) private function syncAllTransforms()
	{
		for (actor in actors)
			actor.syncTransform();
	}

	/**
	 * Runs a physics step.
	 * @param dt - Delta time.
	 */
	override public function physicsStep(dt:Float)
	{
		super.physicsStep(dt);
		pxScene.simulate(timeStep);
		pxScene.fetchResults(true);
		pxControllerMgr.computeInteractions(timeStep);
	}

	/**
	 * Updates this world.
	 * @param dt - Delta time.
	 */
	override public function update(dt:Float)
	{
		super.update(dt);
		step(dt);
		syncAllTransforms();
	}

	/**
	 * Safely destroys this world. If `destroyActorsOnDestroy` is true,
	 * it also destroys all actors in this world first.
	 * 
	 * @see destroyActorsOnDestroy
	 */
	override public function destroy()
	{
		super.destroy();

		var localActors = [];
		if (destroyActorsOnDestroy)
			localActors = actors.copy();
		for (actor in actors)
			remove(actor);
		if (destroyActorsOnDestroy)
			for (actor in localActors)
				actor.destroy();

		pxControllerMgr.release();
		pxScene.release();
		dispatcher.release();
		pxPhysics.release();
		#if FPX_PVD
		if (pxPvd != null)
		{
			var transport = pxPvd.getTransport();
			pxPvd.release();
			transport.release();
		}
		#end
		pxFoundation.release();
		super.destroy();
	}
}
#end
