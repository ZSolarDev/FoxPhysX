# FoxPhysX

PhysX bindings for [FoxLite](https://github.com/dwdvIl/foxlite), the 3D renderer for HaxeFlixel. Add rigid body dynamics, static colliders, and a kinematic character controller to your FoxLite scenes with ease!

## Features

- **`FoxPhysXWorld`**: a physics world you attach directly to a `FoxScene`.
- **Rigid bodies**: dynamic and static bodies that automatically sync to `FoxModel` transforms.
- **Kinematic character controller**: capsule controller with a callback for shape hits (pushing boxes, triggers, etc.)
- **Default player controller**: drop-in WASD + jump movement, with input supplied through a simple handler
- **Partial PhysX access**: `physx.*` externs for materials, shapes, geometries, planes, and rigid body extensions. These expose *many* things, but PhysX is quite a big/complex library. The whole thing is not exposed yet, but a lot of it is, and it's very usable. FoxPhysX exposes PhysX 4.1.1(I am not exposing PhysX 5).

## Installation

```
haxelib install foxphysx
```

Add it to your `Project.xml`:

```xml
<haxelib name="foxlite" />
<haxelib name="foxphysx" />
```

## Quick Start

### 1. Create a physics world

```haxe
foxScene = new FoxScene(FlxG.width, FlxG.height);
add(foxScene);

physXWorld = new FoxPhysXWorld();
foxScene.physicsWorld = physXWorld;
```

### 2. Add a ground plane

```haxe
var physics:PxPhysics = physXWorld.pxPhysics;
var material:PxMaterial = physics.createMaterial(0.5, 0.5, 0.3); // static friction, dynamic friction, restitution

var ground:PxRigidStatic = PxSimpleFactory.createPlane(physics, new PxPlane(0, 1, 0, 0), material);
physXWorld.add(new FoxPhysXBody(null, ground));
```

A `null` model means the body has no visual, which is handy for invisible colliders.

### 3. Add a dynamic box

```haxe
var model = new FoxModel();
model.addMesh(new FoxCubeMesh(1, 1, 1, myMaterial));
foxScene.add(model);

var dynBody:PxRigidDynamic = physics.createRigidDynamic(
    new PxTransform(new PxVec3(0, 5, 0), PxQuat.identity())
);
var shape = physics.createShape(PxBoxGeometry.create(0.5, 0.5, 0.5), material);
dynBody.attachShape(shape);
PxRigidBodyExt.updateMassAndInertia(dynBody, 10); // density

// The third argument "true" marks the body as dynamic so the model follows it
physXWorld.add(new FoxPhysXBody(model, dynBody, true));
```

### 4. Add a static box

```haxe
var model = new FoxModel();
model.addMesh(new FoxCubeMesh(w, h, d, myMaterial));
model.setPosition(x, y, z);
foxScene.add(model);

var actor = physics.createRigidStatic(new PxTransform(new PxVec3(x, y, z), PxQuat.identity()));
actor.attachShape(physics.createShape(PxBoxGeometry.create(w * 0.5, h * 0.5, d * 0.5), material));

physXWorld.add(new FoxPhysXBody(model, actor));
```

> Note: `FoxCubeMesh` takes full dimensions, while `PxBoxGeometry` takes **half extents**.

## Character Controller

### Create the controller

```haxe
var pxController = FoxKinematicControllerFactory.createCapsule(
    physXWorld.pxControllerMgr,
    material,
    0.5, // radius
    1.8, // height
    new Vector3D(0, 2, 10), // start position
    onShapeHit, // hit callback (optional behavior, see below)
    physXWorld
);

kinematicController = new FoxKinematicController(playerModel, pxController);
physXWorld.add(kinematicController);
```

### Handle shape hits

The hit callback fires when the controller touches another shape. This example pushes dynamic bodies:

```haxe
(hit:FoxPhysXShapeHit) ->
{
    if (hit.actor != null && hit.actor.bodyType == FoxPhysicsBodyType.DYNAMIC)
    {
        var pushForce = 3.0;
        var cur = hit.actor.getLinearVelocity();
        hit.actor.setLinearVelocity(new Vector3D(
            -hit.worldNormal.x * pushForce,
            cur.y,
            -hit.worldNormal.z * pushForce
        ));
    }
}
```

### Default player controller

`FoxDefaultPlayerController` handles gravity, movement, and jumping. You only provide the input:

```haxe
var handler:FoxDefaultPlayerHandler = {
    getInputDir: function():Vector3D
    {
        var dir = new Vector3D(0, 0, 0);
        if (FlxG.keys.pressed.W) dir.z -= 1;
        if (FlxG.keys.pressed.S) dir.z += 1;
        if (FlxG.keys.pressed.A) dir.x -= 1;
        if (FlxG.keys.pressed.D) dir.x += 1;
        return dir;
    },
    getIsJumping: function():Bool
    {
        return FlxG.keys.justPressed.SPACE;
    }
};

defaultPlayerController = new FoxDefaultPlayerController(kinematicController, physXWorld, handler);
foxScene.add(defaultPlayerController);
```

Because input goes through the handler, you can swap in gamepad, touch, anything else without changing the controller. Although, you should make your own if you're making something more serious/complex. This is just a simple implementation for testing/debugging purposes.

# PhysX externs

The `physx.*` package exposes the PhysX types used above:

`PxPhysics`, `PxMaterial`, `PxRigidDynamic`, `PxRigidStatic`, `PxTransform`, `PxVec3`, `PxQuat`, `PxPlane`, `PxBoxGeometry`, `PxSphereGeometry`, `PxRigidBodyExt`, `PxSimpleFactory`

And more. For more info, check out [PhysHx](https://github.com/ZSolarDev/PhysHx).