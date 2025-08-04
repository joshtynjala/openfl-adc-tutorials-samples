
import openfl.Lib;
import openfl.Vector;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.Context3DVertexBufferFormat;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.Program3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.textures.Texture;
import openfl.events.Event;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import openfl.utils.AGALMiniAssembler;
import openfl.utils.Assets;

class HelloTriangleTextured extends Sprite
{
    private var texture:Texture;

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
            -0.3,-0.3, 0.0, 1.0, 0.0, // x, y, z, u, v
            -0.3, 0.3, 0.0, 0.0, 1.0,
             0.3, 0.3, 0.0, 1.0, 1.0);

        // Create VertexBuffer3D. 3 vertices, of 5 Numbers each
        vertexBuffer = context3D.createVertexBuffer(3, 5);
        // Upload VertexBuffer3D to GPU. Offset 0, 3 vertices
        vertexBuffer.uploadFromVector(vertices, 0, 3);

        var indices:Vector<UInt> = Vector.ofValues(0, 1, 2);

        // Create IndexBuffer3D. Total of 3 indices. 1 triangle of 3 vertices
        indexBuffer = context3D.createIndexBuffer(3);
        // Upload IndexBuffer3D to GPU. Offset 0, count 3
        indexBuffer.uploadFromVector(indices, 0, 3);

        var bitmapData:BitmapData = Assets.getBitmapData("assets/img/RockSmooth.jpg");
        texture = context3D.createTexture(bitmapData.width, bitmapData.height, Context3DTextureFormat.BGRA, false);
        texture.uploadFromBitmapData(bitmapData);

        var vertexShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();
        vertexShaderAssembler.assemble(Context3DProgramType.VERTEX,
            "m44 op, va0, vc0\n" + // pos to clipspace
            "mov v0, va1" // copy UV
        );

        var fragmentShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();
        fragmentShaderAssembler.assemble(Context3DProgramType.FRAGMENT,
            "tex ft1, v0, fs0 <2d>\n" +
            "mov oc, ft1"
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
        // UV to attribute register 1
        context3D.setVertexBufferAt(1, vertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_2);
        // assign texture to texture sampler 0
        context3D.setTextureAt(0, texture);
        // assign shader program
        context3D.setProgram(program);

        var m:Matrix3D = new Matrix3D();
        m.appendRotation(Lib.getTimer() / 40.0, Vector3D.Z_AXIS);
        context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m, true);

        context3D.drawTriangles(indexBuffer);

        context3D.present();
    }
}