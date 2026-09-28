package foxlite.physics.util;

#if (physhx && cpp)
import openfl.geom.Vector3D;

/**
 * The player's input handler.
 * 
 * @see `FoxDefaultPlayerController`
 */
typedef FoxDefaultPlayerHandler =
{
	/**
	 * Gets the desired horizontal movement direction (x, z), *NOT*
	 * normalized/scaled. It's just a raw direction, it'll normalize the vector automatically.
	 */
	var getInputDir:Void->Vector3D;

	/**
	 * Whether the jump input was pressed.
	 */
	var getIsJumping:Void->Bool;
}
#end
