package foxlite.physics.util;

#if (physhx && cpp)
import foxlite.physics.kinematics.FoxKinematicController;
import openfl.geom.Vector3D;

/**
 * The default player controller. This allows for basic movement handling and jumping in
 * a PhysX world, by controlling a FoxKinematicController.
 */
class FoxDefaultPlayerController extends FoxBasic
{
	/**
	 * The kinematic controller this controller uses.
	 */
	public var controller:FoxKinematicController;

	/**
	 * The PhysX world this controller belongs to.
	 */
	public var world:FoxPhysXWorld;

	/**
	 * The input handler this controller uses.
	 */
	public var handler:FoxDefaultPlayerHandler;

	/**
	 * The player's current velocity.
	 */
	public var velocity:Vector3D = new Vector3D(0, 0, 0);

	/**
	 * The player's horizontal speed.
	 */
	public var moveSpeed:Float = 6.0;

	/**
	 * The player's jump force.
	 */
	public var jumpForce:Float = 8.0;

	/**
	 * The minimum distance to move per tick.
	 */
	public var minMoveDist:Float = 0.0001;

	/**
	 * Creates a new default player controller.
	 * @param controller - The kinematic controller this controller uses.
	 * @param world - The PhysX world this controller belongs to.
	 * @param handler - The input handler this controller uses.
	 */
	public function new(controller:FoxKinematicController, world:FoxPhysXWorld, handler:FoxDefaultPlayerHandler)
	{
		super();

		this.controller = controller;
		this.world = world;
		this.handler = handler;
	}

	/**
	 * Updates this player controller.
	 * @param dt - Delta time.
	 */
	override public function physicsUpdate(dt:Float)
	{
		super.physicsUpdate(dt);
		tick(handler.getInputDir(), handler.getIsJumping(), dt);
	}

	/**
	 * This is automatically called on this player controller's physics update.
	 * @param inputDir - The desired horizontal movement direction (x, z), *NOT*
	 * normalized/scaled. Pass in a raw direction, and it'll normalize the vector automatically.
	 * @param jumpPressed - Whether the jump input was pressed this tick.
	 * @param dt - Fixed physics timestep.
	**/
	public function tick(inputDir:Vector3D, jumpPressed:Bool, dt:Float)
	{
		applyGravity(dt);
		applyHorizontalInput(inputDir);
		applyJump(jumpPressed);

		var disp = velocity.clone();
		disp.scaleBy(dt);

		controller.move(disp, minMoveDist, dt);

		if (controller.isGrounded() && velocity.y < 0)
			velocity.y = 0;

		if (controller.isTouchingCeiling() && velocity.y > 0)
			velocity.y = 0;
	}

	@:dox(hide) private function applyGravity(dt:Float)
	{
		var g = world.pxScene.getGravity();
		velocity.x += g.x * dt;
		velocity.y += g.y * dt;
		velocity.z += g.z * dt;
	}

	@:dox(hide) private function applyHorizontalInput(inputDir:Vector3D)
	{
		var dir = inputDir.clone();
		if (dir.length > 0)
			dir.normalize();

		velocity.x = dir.x * moveSpeed;
		velocity.z = dir.z * moveSpeed;
	}

	@:dox(hide) private function applyJump(jumpPressed:Bool)
	{
		if (jumpPressed && controller.isGrounded())
			velocity.y = jumpForce;
	}
}
#end
