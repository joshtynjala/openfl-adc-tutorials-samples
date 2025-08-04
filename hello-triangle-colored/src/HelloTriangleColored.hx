
import openfl.Lib;
import openfl.Vector;
import openfl.display.Sprite;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DVertexBufferFormat;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.Program3D;
import openfl.display3D.VertexBuffer3D;
import openfl.events.Event;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import openfl.utils.AGALMiniAssembler;

class HelloTriangleColored extends Sprite
{
    private var context3D:Context3D;
    private var program:Program3D;
    private var vertexBuffer:VertexBuffer3D;
    private var indexBuffer:IndexBuffer3D;

    public function new()
    {
        super();

        stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, initStage3D);
        stage.stage3Ds[0].requestContext3D();

        addEventListener(Event.ENTER_FRAME, onRender);

    }

    private function initStage3D(e:Event):Void
    {
        context3D = stage.stage3Ds[0].context3D;
        context3D.configureBackBuffer(800, 600, 1, true);

        var vertices:Vector<Float> = Vector.ofValues(
            -0.3,-0.3, 0.0, 1.0, 0.0, 0.0, // x, y, z, r, g, b
            -0.3, 0.3, 0.0, 0.0, 1.0, 0.0,
             0.3, 0.3, 0.0, 0.0, 0.0, 1.0);

        // Create VertexBuffer3D. 3 vertices, of 6 Floats each
        vertexBuffer = context3D.createVertexBuffer(3, 6);
        // Upload VertexBuffer3D to GPU. Offset 0, 3 vertices
        vertexBuffer.uploadFromVector(vertices, 0, 3);

        var indices:Vector<UInt> = Vector.ofValues(0, 1, 2);

        // Create IndexBuffer3D. Total of 3 indices. 1 triangle of 3 vertices
        indexBuffer = context3D.createIndexBuffer(3);
        // Upload IndexBuffer3D to GPU. Offset 0, count 3
        indexBuffer.uploadFromVector(indices, 0, 3);

        var vertexShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();
        vertexShaderAssembler.assemble(Context3DProgramType.VERTEX,
            "m44 op, va0, vc0\n" + // pos to clipspace
            "mov v0, va1" // copy color
        );

        var fragmentShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();
        fragmentShaderAssembler.assemble(Context3DProgramType.FRAGMENT,

            "mov oc, v0"
        );

        program = context3D.createProgram();
        program.upload(vertexShaderAssembler.agalcode, fragmentShaderAssembler.agalcode);
    }

    private function onRender(e:Event):Void
    {
        if (context3D == null)
            return;

        context3D.clear(1, 1, 1, 1);

        // vertex position to attribute register 0
        context3D.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
        // color to attribute register 1
        context3D.setVertexBufferAt(1, vertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_3);
        // assign shader program
        context3D.setProgram(program);

        var m:Matrix3D = new Matrix3D();
        m.appendRotation(Lib.getTimer() / 40.0, Vector3D.Z_AXIS);
        context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m, true);

        context3D.drawTriangles(indexBuffer);

        context3D.present();
    }
}