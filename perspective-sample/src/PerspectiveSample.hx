import openfl.Assets;
import openfl.Lib;
import openfl.Vector;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.display.StageAlign;
import openfl.display.StageScaleMode;
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
import openfl.utils.PerspectiveMatrix3D;

class PerspectiveSample extends Sprite
{
    private var context3D:Context3D;
    private var vertexbuffer:VertexBuffer3D;
    private var indexBuffer:IndexBuffer3D;
    private var program:Program3D;
    private var texture:Texture;
    private var projectionTransform:PerspectiveMatrix3D;

    public function new()
    {
        super();

        stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, initStage3D);
        stage.stage3Ds[0].requestContext3D();

        stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.align = StageAlign.TOP_LEFT;

        addEventListener(Event.ENTER_FRAME, onRender);
    }

    private function initStage3D(e:Event):Void
    {
        context3D = stage.stage3Ds[0].context3D;
        context3D.configureBackBuffer(800, 600, 1, true);

        var vertices:Vector<Float> = Vector.ofValues(
            -0.3,-0.3, 0.0, 0.0, 0.0, // x, y, z, u, v
            -0.3, 0.3, 0.0, 0.0, 1.0,
             0.3, 0.3, 0.0, 1.0, 1.0,
             0.3,-0.3, 0.0, 1.0, 0.0);

        // 4 vertices, of 5 Floats each
        vertexbuffer = context3D.createVertexBuffer(4, 5);
        // offset 0, 4 vertices
        vertexbuffer.uploadFromVector(vertices, 0, 4);

        // total of 6 indices. 2 triangles by 3 vertices each
        indexBuffer = context3D.createIndexBuffer(6);

        // offset 0, count 6
        indexBuffer.uploadFromVector(Vector.ofValues(0, 1, 2, 2, 3, 0), 0, 6);

        var bitmapData:BitmapData = Assets.getBitmapData("assets/img/RockSmooth.jpg");
        texture = context3D.createTexture(bitmapData.width, bitmapData.height, Context3DTextureFormat.BGRA, false);
        texture.uploadFromBitmapData(bitmapData);

        var vertexShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();
        vertexShaderAssembler.assemble(Context3DProgramType.VERTEX,
            "m44 op, va0, vc0\n" + // pos to clipspace
            "mov v0, va1" // copy uv
        );
        var fragmentShaderAssembler:AGALMiniAssembler= new AGALMiniAssembler();
        fragmentShaderAssembler.assemble(Context3DProgramType.FRAGMENT,
            "tex ft1, v0, fs0 <2d,linear,nomip>\n" +
            "mov oc, ft1"
        );

        program = context3D.createProgram();
        program.upload(vertexShaderAssembler.agalcode, fragmentShaderAssembler.agalcode);

        projectionTransform = new PerspectiveMatrix3D();
        var aspect:Float = 4/3;
        var zNear:Float = 0.1;
        var zFar:Float = 1000;
        var fov:Float = 45*Math.PI/180;
        projectionTransform.perspectiveFieldOfViewLH(fov, aspect, zNear, zFar);
    }

    private function onRender(e:Event):Void
    {
        if (context3D == null)
            return;

        context3D.clear(1, 1, 1, 1);

        // vertex position to attribute register 0
        context3D.setVertexBufferAt(0, vertexbuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
        // uv coordinates to attribute register 1
        context3D.setVertexBufferAt(1, vertexbuffer, 3, Context3DVertexBufferFormat.FLOAT_2);
        // assign texture to texture sampler 0
        context3D.setTextureAt(0, texture);
        // assign shader program
        context3D.setProgram(program);

        var m:Matrix3D = new Matrix3D();
        m.appendRotation(Lib.getTimer()/30, Vector3D.Y_AXIS);
        m.appendRotation(Lib.getTimer()/10, Vector3D.X_AXIS);
        m.appendTranslation(0, 0, 2);
        m.append(projectionTransform);

        context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m, true);

        context3D.drawTriangles(indexBuffer);

        context3D.present();
    }
}