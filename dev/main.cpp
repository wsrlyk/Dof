#include "main.h"

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nShowCmd)
{
#if defined _DEBUG
    _CrtSetDbgFlag(_CRTDBG_LEAK_CHECK_DF | _CRTDBG_ALLOC_MEM_DF);
    _CrtSetReportMode(_CRT_ASSERT, _CRTDBG_MODE_FILE);
    _CrtSetReportFile(_CRT_ASSERT, _CRTDBG_FILE_STDERR);
#endif

    MSG msg = {0};
    WNDCLASSEX wcl = {0};

    wcl.cbSize = sizeof(wcl);
    wcl.style = CS_OWNDC | CS_HREDRAW | CS_VREDRAW;
    wcl.lpfnWndProc = WindowProc;
    wcl.cbClsExtra = 0;
    wcl.cbWndExtra = 0;
    wcl.hInstance = g_hInstance = hInstance;
    wcl.hIcon = LoadIcon(0, IDI_APPLICATION);
    wcl.hCursor = LoadCursor(0, IDC_ARROW);
    wcl.hbrBackground = 0;
    wcl.lpszMenuName = MAKEINTRESOURCE(MENU_FIXED_FUNC);
    wcl.lpszClassName = "GLWindowClass";
    wcl.hIconSm = 0;

    if (!RegisterClassEx(&wcl))
        return 0;

    g_hWnd = CreateAppWindow(wcl, APP_TITLE);

    if (g_hWnd)
    {
        SetProcessorAffinity();

        if (Init())
        {
            ShowWindow(g_hWnd, nShowCmd);
            UpdateWindow(g_hWnd);

            while (true)
            {
                while (PeekMessage(&msg, 0, 0, 0, PM_REMOVE))
                {
                    if (msg.message == WM_QUIT)
                        break;

                    TranslateMessage(&msg);
                    DispatchMessage(&msg);
                }

                if (msg.message == WM_QUIT)
                    break;

                if (g_hasFocus)
                {
                    UpdateFrame(GetElapsedTimeInSeconds());
                    DrawFrame();
                    SwapBuffers(g_hDC);
                }
                else
                {
                    WaitMessage();
                }
            }
        }

        Cleanup();
        UnregisterClass(wcl.lpszClassName, hInstance);
    }

    return static_cast<int>(msg.wParam);
}

LRESULT CALLBACK WindowProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    static char szFilename[MAX_PATH];

    switch (msg)
    {
    case WM_ACTIVATE:
        switch (wParam)
        {
        default:
            break;

        case WA_ACTIVE:
        case WA_CLICKACTIVE:
            g_hasFocus = true;
            break;

        case WA_INACTIVE:
            if (g_isFullScreen)
                ShowWindow(hWnd, SW_MINIMIZE);
            g_hasFocus = false;
            break;
        }
        break;

    case WM_CHAR:
        switch (static_cast<int>(wParam))
        {
        case VK_ESCAPE:
            PostMessage(hWnd, WM_CLOSE, 0, 0);
            break;

        case 'r':
        case 'R':
            PostMessage(hWnd, WM_COMMAND, MAKEWPARAM(MENU_VIEW_RESET, 0), 0);
            break;

        case 't':
        case 'T':
            PostMessage(hWnd, WM_COMMAND, MAKEWPARAM(MENU_VIEW_TEXTURED, 0), 0);
            break;

        case 'w':
        case 'W':
            PostMessage(hWnd, WM_COMMAND, MAKEWPARAM(MENU_VIEW_WIREFRAME, 0), 0);
            break;

        default:
            break;
        }
        break;

    case WM_COMMAND:
        ProcessMenu(hWnd, wParam, lParam);
        return 0;

    case WM_CREATE:
        DragAcceptFiles(hWnd, TRUE);
        break;

    case WM_DESTROY:
        DragAcceptFiles(hWnd, FALSE);
        PostQuitMessage(0);
        return 0;

    case WM_DROPFILES:
        DragQueryFile(reinterpret_cast<HDROP>(wParam), 0, szFilename, MAX_PATH);
        DragFinish(reinterpret_cast<HDROP>(wParam));

        try
        {
            if (strstr(szFilename, ".obj") || strstr(szFilename, ".OBJ"))
            {
                UnloadModel();
                LoadModel(szFilename);
                ResetCamera();
            }
            else
            {
                throw std::runtime_error("File is not a valid .OBJ file");
            }            
        }
        catch (const std::runtime_error &e)
        {
            Log(e.what());
        }
        return 0;

    case WM_SIZE:
        g_windowWidth = static_cast<int>(LOWORD(lParam));
        g_windowHeight = static_cast<int>(HIWORD(lParam));
        break;

    case WM_SYSKEYDOWN:
        if (wParam == VK_RETURN)
            PostMessage(hWnd, WM_COMMAND, MAKEWPARAM(MENU_VIEW_FULLSCREEN, 0), 0);
        break;

    default:
        ProcessMouseInput(hWnd, msg, wParam, lParam);
        break;
    }

    return DefWindowProc(hWnd, msg, wParam, lParam);
}

void Cleanup()
{
    CleanupApp();

    if (g_hDC)
    {
        if (g_hRC)
        {
            wglMakeCurrent(g_hDC, 0);
            wglDeleteContext(g_hRC);
            g_hRC = 0;
        }

        ReleaseDC(g_hWnd, g_hDC);
        g_hDC = 0;
    }
}

void CleanupApp()
{
    UnloadModel();

    if (g_nullTexture)
    {
        glDeleteTextures(1, &g_nullTexture);
        g_nullTexture = 0;
    }

    if (g_supportsProgrammablePipeline)
    {
        glUseProgram(0);

        if (g_blinnPhongShader)
        {
            glDeleteProgram(g_blinnPhongShader);
            g_blinnPhongShader = 0;
        }

        if (g_normalMappingShader)
        {
            glDeleteProgram(g_normalMappingShader);
            g_normalMappingShader = 0;
        }
    }
}

GLuint CompileShader(GLenum type, const GLchar *pszSource, GLint length)
{
    // Compiles the shader given it's source code. Returns the shader object.
    // A std::string object containing the shader's info log is thrown if the
    // shader failed to compile.
    //
    // 'type' is either GL_VERTEX_SHADER or GL_FRAGMENT_SHADER.
    // 'pszSource' is a C style string containing the shader's source code.
    // 'length' is the length of 'pszSource'.

    GLuint shader = glCreateShader(type);

    if (shader)
    {
        GLint compiled = 0;

        glShaderSource(shader, 1, &pszSource, &length);
        glCompileShader(shader);
        glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);

        if (!compiled)
        {
            GLsizei infoLogSize = 0;
            std::string infoLog;

            glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLogSize);
            infoLog.resize(infoLogSize);
            glGetShaderInfoLog(shader, infoLogSize, &infoLogSize, &infoLog[0]);

            throw infoLog;
        }
    }

    return shader;
}

HWND CreateAppWindow(const WNDCLASSEX &wcl, const char *pszTitle)
{
    // Create a window that is centered on the desktop. It's exactly 1/4 the
    // size of the desktop. Don't allow it to be resized.

    DWORD wndExStyle = WS_EX_OVERLAPPEDWINDOW;
    DWORD wndStyle = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU |
        WS_MINIMIZEBOX | WS_CLIPCHILDREN | WS_CLIPSIBLINGS;

    HWND hWnd = CreateWindowEx(wndExStyle, wcl.lpszClassName, pszTitle,
        wndStyle, 0, 0, 0, 0, 0, 0, wcl.hInstance, 0);

    if (hWnd)
    {
        int screenWidth = GetSystemMetrics(SM_CXSCREEN);
        int screenHeight = GetSystemMetrics(SM_CYSCREEN);
		g_windowWidth = screenWidth *  1/ 2;
		g_windowHeight = screenHeight *1 / 2;
		int left = (screenWidth - g_windowWidth) / 2;
		int top = (screenHeight - g_windowHeight) / 2;
		RECT rc = {0};

		SetRect(&rc, left, top, left + g_windowWidth, top + g_windowHeight);
        AdjustWindowRectEx(&rc, wndStyle, FALSE, wndExStyle);
        MoveWindow(hWnd, rc.left, rc.top, rc.right - rc.left, rc.bottom - rc.top, TRUE);

        GetClientRect(hWnd, &rc);
        g_windowWidth = rc.right - rc.left;
        g_windowHeight = rc.bottom - rc.top;
    }

    return hWnd;
}

GLuint CreateNullTexture(int width, int height)
{
    // Create an empty white texture. This texture is applied to OBJ models
    // that don't have any texture maps. This trick allows the same shader to
    // be used to draw the OBJ model with and without textures applied.

    int pitch = ((width * 32 + 31) & ~31) >> 3; // align to 4-byte boundaries
    std::vector<GLubyte> pixels(pitch * height, 255);
    GLuint texture = 0;

    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0, GL_BGRA,
        GL_UNSIGNED_BYTE, &pixels[0]);

    return texture;
}

void DrawFrame()
{
    glViewport(0, 0, g_windowWidth, g_windowHeight);
    glClearColor(0.3f, 0.5f, 0.9f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluPerspective(CAMERA_FOVY,
        static_cast<float>(g_windowWidth) / static_cast<float>(g_windowHeight),
        CAMERA_ZNEAR, CAMERA_ZFAR);

    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    gluLookAt(g_cameraPos[0], g_cameraPos[1], g_cameraPos[2],
        g_targetPos[0], g_targetPos[1], g_targetPos[2],
        0.0f, 1.0f, 0.0f);

    glRotatef(g_pitch, 1.0f, 0.0f, 0.0f);
    glRotatef(g_heading, 0.0f, 1.0f, 0.0f);

//    if (g_supportsProgrammablePipeline)
//        DrawModelUsingProgrammablePipeline();
//    else
//        DrawModelUsingFixedFuncPipeline();
//	RenderAverageColors();
	RenderFrontToBackPeeling();
}

void DrawModelUsingFixedFuncPipeline()
{
    const ModelOBJ::Mesh *pMesh = 0;
    const ModelOBJ::Material *pMaterial = 0;
    const ModelOBJ::Vertex *pVertices = 0;
    ModelTextures::const_iterator iter;

    for (int i = 0; i < g_model.getNumberOfMeshes(); ++i)
    {
        pMesh = &g_model.getMesh(i);
        pMaterial = pMesh->pMaterial;
        pVertices = g_model.getVertexBuffer();

        glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, pMaterial->ambient);
        glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, pMaterial->diffuse);
        glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, pMaterial->specular);
        glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, pMaterial->shininess * 128.0f);

        if (g_enableTextures)
        {
            iter = g_modelTextures.find(pMaterial->colorMapFilename);

            if (iter == g_modelTextures.end())
            {
                glDisable(GL_TEXTURE_2D);
            }
            else
            {
                glEnable(GL_TEXTURE_2D);
                glBindTexture(GL_TEXTURE_2D, iter->second);
            }
        }
        else
        {
            glDisable(GL_TEXTURE_2D);
        }

        if (g_model.hasPositions())
        {
            glEnableClientState(GL_VERTEX_ARRAY);
            glVertexPointer(3, GL_FLOAT, g_model.getVertexSize(),
                g_model.getVertexBuffer()->position);
        }

        if (g_model.hasTextureCoords())
        {
            glEnableClientState(GL_TEXTURE_COORD_ARRAY);
            glTexCoordPointer(2, GL_FLOAT, g_model.getVertexSize(),
                g_model.getVertexBuffer()->texCoord);
        }

        if (g_model.hasNormals())
        {
            glEnableClientState(GL_NORMAL_ARRAY);
            glNormalPointer(GL_FLOAT, g_model.getVertexSize(),
                g_model.getVertexBuffer()->normal);
        }

        glDrawElements(GL_TRIANGLES, pMesh->triangleCount * 3, GL_UNSIGNED_INT,
            g_model.getIndexBuffer() + pMesh->startIndex);

        if (g_model.hasNormals())
            glDisableClientState(GL_NORMAL_ARRAY);

        if (g_model.hasTextureCoords())
            glDisableClientState(GL_TEXTURE_COORD_ARRAY);

        if (g_model.hasPositions())
            glDisableClientState(GL_VERTEX_ARRAY);
    }
}

void DrawModelUsingProgrammablePipeline()
{
    const ModelOBJ::Mesh *pMesh = 0;
    const ModelOBJ::Material *pMaterial = 0;
    const ModelOBJ::Vertex *pVertices = 0;
    ModelTextures::const_iterator iter;
    GLuint texture = 0;

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    for (int i = 0; i < g_model.getNumberOfMeshes(); ++i)
    {
        pMesh = &g_model.getMesh(i);
        pMaterial = pMesh->pMaterial;
        pVertices = g_model.getVertexBuffer();

        glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, pMaterial->ambient);
        glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, pMaterial->diffuse);
        glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, pMaterial->specular);
        glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, pMaterial->shininess * 128.0f);

        if (pMaterial->bumpMapFilename.empty())
        {
            // Per fragment Blinn-Phong code path.
//			blinnphong_program.bind();
            glUseProgram(g_blinnPhongShader);

            // Bind the color map texture.

            texture = g_nullTexture;

            if (g_enableTextures)
            {
                iter = g_modelTextures.find(pMaterial->colorMapFilename);

                if (iter != g_modelTextures.end())
                    texture = iter->second;
            }

            glActiveTexture(GL_TEXTURE0);
            glEnable(GL_TEXTURE_2D);
            glBindTexture(GL_TEXTURE_2D, texture);

            // Update shader parameters.
//					blinnphong_program.bindTexture2D("colorMap", texture, 0);
//					blinnphong_program.setUniform("materialAlpha", (GLfloat*)&pMaterial->alpha, 1);

			glUniform1i(glGetUniformLocation(
				g_blinnPhongShader, "colorMap"), 0);
			glUniform1f(glGetUniformLocation(
				g_blinnPhongShader, "materialAlpha"), pMaterial->alpha);
		}
        else
        {
            // Normal mapping code path.

            glUseProgram(g_normalMappingShader);

            // Bind the normal map texture.

            iter = g_modelTextures.find(pMaterial->bumpMapFilename);

            if (iter != g_modelTextures.end())
            {
                glActiveTexture(GL_TEXTURE1);
                glEnable(GL_TEXTURE_2D);
                glBindTexture(GL_TEXTURE_2D, iter->second);
            }

            // Bind the color map texture.

            texture = g_nullTexture;

            if (g_enableTextures)
            {
                iter = g_modelTextures.find(pMaterial->colorMapFilename);

                if (iter != g_modelTextures.end())
                    texture = iter->second;
            }

            glActiveTexture(GL_TEXTURE0);
            glEnable(GL_TEXTURE_2D);
            glBindTexture(GL_TEXTURE_2D, texture);

            // Update shader parameters.

            glUniform1i(glGetUniformLocation(
                g_normalMappingShader, "colorMap"), 0);
            glUniform1i(glGetUniformLocation(
                g_normalMappingShader, "normalMap"), 1);
            glUniform1f(glGetUniformLocation(
                g_normalMappingShader, "materialAlpha"), pMaterial->alpha);
        }        

        // Render mesh.

        if (g_model.hasPositions())
        {
            glEnableClientState(GL_VERTEX_ARRAY);
            glVertexPointer(3, GL_FLOAT, g_model.getVertexSize(),
                g_model.getVertexBuffer()->position);
        }

        if (g_model.hasTextureCoords())
        {
            glClientActiveTexture(GL_TEXTURE0);
            glEnableClientState(GL_TEXTURE_COORD_ARRAY);
            glTexCoordPointer(2, GL_FLOAT, g_model.getVertexSize(),
                g_model.getVertexBuffer()->texCoord);
        }

        if (g_model.hasNormals())
        {
            glEnableClientState(GL_NORMAL_ARRAY);
            glNormalPointer(GL_FLOAT, g_model.getVertexSize(),
                g_model.getVertexBuffer()->normal);
        }

        if (g_model.hasTangents())
        {
            glClientActiveTexture(GL_TEXTURE1);
            glEnableClientState(GL_TEXTURE_COORD_ARRAY);
            glTexCoordPointer(4, GL_FLOAT, g_model.getVertexSize(),
                g_model.getVertexBuffer()->tangent);
        }

        glDrawElements(GL_TRIANGLES, pMesh->triangleCount * 3, GL_UNSIGNED_INT,
            g_model.getIndexBuffer() + pMesh->startIndex);

        if (g_model.hasTangents())
        {
            glClientActiveTexture(GL_TEXTURE1);
            glDisableClientState(GL_TEXTURE_COORD_ARRAY);
        }

        if (g_model.hasNormals())
            glDisableClientState(GL_NORMAL_ARRAY);

        if (g_model.hasTextureCoords())
        {
            glClientActiveTexture(GL_TEXTURE0);
            glDisableClientState(GL_TEXTURE_COORD_ARRAY);
        }

        if (g_model.hasPositions())
            glDisableClientState(GL_VERTEX_ARRAY);
    }
//	blinnphong_program.unbind();
    glBindTexture(GL_TEXTURE_2D, 0);
    glUseProgram(0);
    glDisable(GL_BLEND);
}

bool ExtensionSupported(const char *pszExtensionName)
{
    static const char *pszGLExtensions = 0;
    static const char *pszWGLExtensions = 0;

    if (!pszGLExtensions)
        pszGLExtensions = reinterpret_cast<const char *>(glGetString(GL_EXTENSIONS));

    if (!pszWGLExtensions)
    {
        // WGL_ARB_extensions_string.

        typedef const char *(WINAPI * PFNWGLGETEXTENSIONSSTRINGARBPROC)(HDC);

        PFNWGLGETEXTENSIONSSTRINGARBPROC wglGetExtensionsStringARB =
            reinterpret_cast<PFNWGLGETEXTENSIONSSTRINGARBPROC>(
            wglGetProcAddress("wglGetExtensionsStringARB"));

        if (wglGetExtensionsStringARB)
            pszWGLExtensions = wglGetExtensionsStringARB(g_hDC);
    }

    if (!strstr(pszGLExtensions, pszExtensionName))
    {
        if (!strstr(pszWGLExtensions, pszExtensionName))
            return false;
    }

    return true;
}

float GetElapsedTimeInSeconds()
{
    // Returns the elapsed time (in seconds) since the last time this function
    // was called. This elaborate setup is to guard against large spikes in
    // the time returned by QueryPerformanceCounter().

    static const int MAX_SAMPLE_COUNT = 50;

    static float frameTimes[MAX_SAMPLE_COUNT];
    static float timeScale = 0.0f;
    static float actualElapsedTimeSec = 0.0f;
    static INT64 freq = 0;
    static INT64 lastTime = 0;
    static int sampleCount = 0;
    static bool initialized = false;

    INT64 time = 0;
    float elapsedTimeSec = 0.0f;

    if (!initialized)
    {
        initialized = true;
        QueryPerformanceFrequency(reinterpret_cast<LARGE_INTEGER*>(&freq));
        QueryPerformanceCounter(reinterpret_cast<LARGE_INTEGER*>(&lastTime));
        timeScale = 1.0f / freq;
    }

    QueryPerformanceCounter(reinterpret_cast<LARGE_INTEGER*>(&time));
    elapsedTimeSec = (time - lastTime) * timeScale;
    lastTime = time;

    if (fabsf(elapsedTimeSec - actualElapsedTimeSec) < 1.0f)
    {
        memmove(&frameTimes[1], frameTimes, sizeof(frameTimes) - sizeof(frameTimes[0]));
        frameTimes[0] = elapsedTimeSec;

        if (sampleCount < MAX_SAMPLE_COUNT)
            ++sampleCount;
    }

    actualElapsedTimeSec = 0.0f;

    for (int i = 0; i < sampleCount; ++i)
        actualElapsedTimeSec += frameTimes[i];

    if (sampleCount > 0)
        actualElapsedTimeSec /= sampleCount;

    return actualElapsedTimeSec;
}

bool Init()
{
    try
    {
        InitGL();
        InitApp();
        return true;
    }
    catch (const std::exception &e)
    {
        std::ostringstream msg;

        msg << "Application initialization failed!" << std::endl << std::endl;
        msg << e.what();

        Log(msg.str().c_str());
        return false;
    }    
}

void InitApp()
{
    glEnable(GL_TEXTURE_2D);
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);

	//定义一个光源的位置坐标
	GLfloat light_position[]={10.0,10.0,10.0,0.0};
	glLightfv(GL_LIGHT0,GL_POSITION,light_position);


	//定义光源的漫反射颜色（兰色）以及环境光（红色），如果你上机试试这个
	//程序，就可以看出光源的效果。如果没条件，可以想象一下：在淡淡的红色
	//背景光下，受光照的部分呈现纯蓝色，而背光部分呈现红色。
	//你还可以更详细按照上面表格指定其他属性，这里其他就用缺省的了。
	GLfloat light_diffuse[]={0.5,0.5,0.5,0.5};
	glLightfv(GL_LIGHT0,GL_DIFFUSE,light_diffuse);
	GLfloat light_ambient[]={0.3,0.3,0.3,0.3};
	glLightfv(GL_LIGHT0,GL_AMBIENT,light_ambient);

	glEnable(GL_LIGHTING);
    glEnable(GL_LIGHT0);

    glActiveTexture(GL_TEXTURE1);
    glEnable(GL_TEXTURE_2D);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

    glActiveTexture(GL_TEXTURE0);
    glEnable(GL_TEXTURE_2D);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

    if (g_supportsProgrammablePipeline)
    {
        std::string infoLog;

		blinnphong_program.attachVertexShader(SHADER_PATH "blinn_phong_vert.glsl");
		blinnphong_program.attachFragmentShader(SHADER_PATH "blinn_phong_frag.glsl");
		blinnphong_program.link();

		if (!(g_blinnPhongShader = LoadShaderProgramFromResource(
            reinterpret_cast<const char *>(SHADER_BLINN_PHONG), infoLog)))
            throw std::runtime_error("Failed to load Blinn-Phong shader.\n" + infoLog);

        if (!(g_normalMappingShader = LoadShaderProgramFromResource(
            reinterpret_cast<const char *>(SHADER_NORMAL_MAPPING), infoLog)))
            throw std::runtime_error("Failed to load normal mapping shader.\n" + infoLog);

        if (!(g_nullTexture = CreateNullTexture(2, 2)))
            throw std::runtime_error("Failed to create null texture.");
    }

    if (__argc == 2)
    {
        LoadModel(__argv[1]);
		g_model.normalize(10);
   //     ResetCamera();
    }
	BuildShaders();
	InitAccumulationRenderTargets();
	InitFrontPeelingRenderTargets();
	MakeFullScreenQuad();
}

void InitGL()
{
    if (!(g_hDC = GetDC(g_hWnd)))
        throw std::runtime_error("GetDC() failed.");

    int pf = 0;
    PIXELFORMATDESCRIPTOR pfd = {0};
    OSVERSIONINFO osvi = {0};

    pfd.nSize = sizeof(pfd);
    pfd.nVersion = 1;
    pfd.dwFlags = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER;
    pfd.iPixelType = PFD_TYPE_RGBA;
    pfd.cColorBits = 24;
    pfd.cDepthBits = 16;
    pfd.iLayerType = PFD_MAIN_PLANE;

    osvi.dwOSVersionInfoSize = sizeof(OSVERSIONINFO);

    if (!GetVersionEx(&osvi))
        throw std::runtime_error("GetVersionEx() failed.");

    // When running under Windows Vista or later support composition.
    if (osvi.dwMajorVersion > 6 || (osvi.dwMajorVersion == 6 && osvi.dwMinorVersion >= 0))
        pfd.dwFlags |=  PFD_SUPPORT_COMPOSITION;

    ChooseBestMultiSampleAntiAliasingPixelFormat(pf, g_msaaSamples);

    if (!pf)
        pf = ChoosePixelFormat(g_hDC, &pfd);

    if (!SetPixelFormat(g_hDC, pf, &pfd))
        throw std::runtime_error("SetPixelFormat() failed.");

    if (!(g_hRC = wglCreateContext(g_hDC)))
        throw std::runtime_error("wglCreateContext() failed.");

    if (!wglMakeCurrent(g_hDC, g_hRC))
        throw std::runtime_error("wglMakeCurrent() failed.");

   // GL2Init();
	glewInit();

    g_supportsProgrammablePipeline = true;//GL2SupportsGLVersion(2, 0);

    // Check for GL_EXT_texture_filter_anisotropic support.
    if (ExtensionSupported("GL_EXT_texture_filter_anisotropic"))
        glGetFloatv(GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT, &g_maxAnisotrophy);
    else
        g_maxAnisotrophy = 1.0f;
}

GLuint LinkShaders(GLuint vertShader, GLuint fragShader)
{
    // Links the compiled vertex and/or fragment shaders into an executable
    // shader program. Returns the executable shader object. If the shaders
    // failed to link into an executable shader program, then a std::string
    // object is thrown containing the info log.

    GLuint program = glCreateProgram();

    if (program)
    {
        GLint linked = 0;

        if (vertShader)
            glAttachShader(program, vertShader);

        if (fragShader)
            glAttachShader(program, fragShader);

        glLinkProgram(program);
        glGetProgramiv(program, GL_LINK_STATUS, &linked);

        if (!linked)
        {
            GLsizei infoLogSize = 0;
            std::string infoLog;

            glGetProgramiv(program, GL_INFO_LOG_LENGTH, &infoLogSize);
            infoLog.resize(infoLogSize);
            glGetProgramInfoLog(program, infoLogSize, &infoLogSize, &infoLog[0]);

            throw infoLog;
        }

        // Mark the two attached shaders for deletion. These two shaders aren't
        // deleted right now because both are already attached to a shader
        // program. When the shader program is deleted these two shaders will
        // be automatically detached and deleted.

        if (vertShader)
            glDeleteShader(vertShader);

        if (fragShader)
            glDeleteShader(fragShader);
    }

    return program;
}

void LoadModel(const char *pszFilename)
{
    // Import the OBJ file and normalize to unit length.

    SetCursor(LoadCursor(0, IDC_WAIT));

    if (!g_model.import(pszFilename))
    {
        SetCursor(LoadCursor(0, IDC_ARROW));
        throw std::runtime_error("Failed to load model.");
    }

    g_model.normalize();

    // Load any associated textures.
    // Note the path where the textures are assumed to be located.

    const ModelOBJ::Material *pMaterial = 0;
    GLuint textureId = 0;
    std::string::size_type offset = 0;
    std::string filename;

    for (int i = 0; i < g_model.getNumberOfMaterials(); ++i)
    {
        pMaterial = &g_model.getMaterial(i);

        // Look for and load any diffuse color map textures.

        if (pMaterial->colorMapFilename.empty())
            continue;

        // Try load the texture using the path in the .MTL file.
        textureId = LoadTexture(pMaterial->colorMapFilename.c_str());

        if (!textureId)
        {
            offset = pMaterial->colorMapFilename.find_last_of('\\');

            if (offset != std::string::npos)
                filename = pMaterial->colorMapFilename.substr(++offset);
            else
                filename = pMaterial->colorMapFilename;

            // Try loading the texture from the same directory as the OBJ file.
            textureId = LoadTexture((g_model.getPath() + filename).c_str());
        }

        if (textureId)
            g_modelTextures[pMaterial->colorMapFilename] = textureId;

        // Look for and load any normal map textures.

        if (pMaterial->bumpMapFilename.empty())
            continue;

        // Try load the texture using the path in the .MTL file.
        textureId = LoadTexture(pMaterial->bumpMapFilename.c_str());

        if (!textureId)
        {
            offset = pMaterial->bumpMapFilename.find_last_of('\\');

            if (offset != std::string::npos)
                filename = pMaterial->bumpMapFilename.substr(++offset);
            else
                filename = pMaterial->bumpMapFilename;

            // Try loading the texture from the same directory as the OBJ file.
            textureId = LoadTexture((g_model.getPath() + filename).c_str());
        }

        if (textureId)
            g_modelTextures[pMaterial->bumpMapFilename] = textureId;
    }

    SetCursor(LoadCursor(0, IDC_ARROW));

    // Update the window caption.

    std::ostringstream caption;
    const char *pszBareFilename = strrchr(pszFilename, '\\');

    pszBareFilename = (pszBareFilename != 0) ? ++pszBareFilename : pszFilename;
    caption << APP_TITLE << " - " << pszBareFilename;

    SetWindowText(g_hWnd, caption.str().c_str());
}

GLuint LoadShaderProgramFromResource(const char *pResouceId, std::string &infoLog)
{
    infoLog.clear();

    GLuint program = 0;
    std::string buffer;

    // Read the text file containing the GLSL shader program.
    // This file contains 1 vertex shader and 1 fragment shader.
    ReadTextFileFromResource(pResouceId, buffer);

    // Compile and link the vertex and fragment shaders.
    if (buffer.length() > 0)
    {
        const GLchar *pSource = 0;
        GLint length = 0;
        GLuint vertShader = 0;
        GLuint fragShader = 0;

        std::string::size_type vertOffset = buffer.find("[vert]");
        std::string::size_type fragOffset = buffer.find("[frag]");

        try
        {
            // Get the vertex shader source and compile it.
            // The source is between the [vert] and [frag] tags.
            if (vertOffset != std::string::npos)
            {
                vertOffset += 6;        // skip over the [vert] tag
                pSource = reinterpret_cast<const GLchar *>(&buffer[vertOffset]);
                length = static_cast<GLint>(fragOffset - vertOffset);
                vertShader = CompileShader(GL_VERTEX_SHADER, pSource, length);
            }

            // Get the fragment shader source and compile it.
            // The source is between the [frag] tag and the end of the file.
            if (fragOffset != std::string::npos)
            {
                fragOffset += 6;        // skip over the [frag] tag
                pSource = reinterpret_cast<const GLchar *>(&buffer[fragOffset]);
                length = static_cast<GLint>(buffer.length() - fragOffset - 1);
                fragShader = CompileShader(GL_FRAGMENT_SHADER, pSource, length);
            }

            // Now link the vertex and fragment shaders into a shader program.
            program = LinkShaders(vertShader, fragShader);
        }
        catch (const std::string &errors)
        {
            infoLog = errors;
        }
    }

    return program;
}

GLuint LoadTexture(const char *pszFilename)
{
    GLuint id = 0;
    Bitmap bitmap;

    if (bitmap.loadPicture(pszFilename))
    {
        // The Bitmap class loads images and orients them top-down.
        // OpenGL expects bitmap images to be oriented bottom-up.
        bitmap.flipVertical();

        glGenTextures(1, &id);
        glBindTexture(GL_TEXTURE_2D, id);

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

        if (g_maxAnisotrophy > 1.0f)
        {
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT,
                g_maxAnisotrophy);
        }

        gluBuild2DMipmaps(GL_TEXTURE_2D, 4, bitmap.width, bitmap.height,
            GL_BGRA_EXT, GL_UNSIGNED_BYTE, bitmap.getPixels());
    }

    return id;
}

void Log(const char *pszMessage)
{
    MessageBox(0, pszMessage, "Error", MB_ICONSTOP);
}

void ProcessMenu(HWND hWnd, WPARAM wParam, LPARAM lParam)
{
    static char szFilename[MAX_PATH] = {'\0'};
    static OPENFILENAME ofn;

    switch (LOWORD(wParam))
    {
    case MENU_FILE_OPEN:
        ofn.lStructSize = sizeof(ofn);
        ofn.hwndOwner = hWnd;
        ofn.lpstrFilter = "Alias|Wavefront (*.OBJ)\0*.obj\0";
        ofn.lpstrCustomFilter = 0;
        ofn.nFilterIndex = 1;
        ofn.lpstrFile = szFilename;
        ofn.nMaxFile = MAX_PATH;
        ofn.lpstrTitle = "Open File";
        ofn.lpstrFileTitle = 0;
        ofn.lpstrDefExt = 0;
        ofn.Flags = OFN_FILEMUSTEXIST | OFN_READONLY | OFN_PATHMUSTEXIST;

        if (GetOpenFileName(reinterpret_cast<LPOPENFILENAME>(&ofn)))
        {
            UnloadModel();
            LoadModel(szFilename);
            ResetCamera();
        }

        break;

    case MENU_FILE_CLOSE:
        UnloadModel();
        break;

    case MENU_FILE_EXIT:
        SendMessage(hWnd, WM_CLOSE, 0, 0);
        break;

    case MENU_VIEW_FULLSCREEN:
        ToggleFullScreen();

        if (g_isFullScreen)
            CheckMenuItem(GetMenu(hWnd), MENU_VIEW_FULLSCREEN, MF_CHECKED);
        else
            CheckMenuItem(GetMenu(hWnd), MENU_VIEW_FULLSCREEN, MF_UNCHECKED);
        break;

    case MENU_VIEW_RESET:
        ResetCamera();
        break;

    case MENU_VIEW_CULLBACKFACES:
        if (g_cullBackFaces = !g_cullBackFaces)
        {
            glEnable(GL_CULL_FACE);
            CheckMenuItem(GetMenu(hWnd), MENU_VIEW_CULLBACKFACES, MF_CHECKED);
        }
        else
        {
            glDisable(GL_CULL_FACE);
            CheckMenuItem(GetMenu(hWnd), MENU_VIEW_CULLBACKFACES, MF_UNCHECKED);
        }
        break;

    case MENU_VIEW_TEXTURED:
        if (g_enableTextures = !g_enableTextures)
            CheckMenuItem(GetMenu(hWnd), MENU_VIEW_TEXTURED, MF_CHECKED);
        else
            CheckMenuItem(GetMenu(hWnd), MENU_VIEW_TEXTURED, MF_UNCHECKED);
        break;

    case MENU_VIEW_WIREFRAME:
        if (g_enableWireframe = !g_enableWireframe)
        {
            glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
            CheckMenuItem(GetMenu(hWnd), MENU_VIEW_WIREFRAME, MF_CHECKED);
        }
        else
        {
            glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
            CheckMenuItem(GetMenu(hWnd), MENU_VIEW_WIREFRAME, MF_UNCHECKED);
        }
        break;

    default:
        break;
    }
}

void ProcessMouseInput(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    // Use the left mouse button to track the camera.
    // Use the middle mouse button to dolly the camera.
    // Use the right mouse button to orbit the camera.

    enum CameraMode {CAMERA_NONE, CAMERA_TRACK, CAMERA_DOLLY, CAMERA_ORBIT};

    static CameraMode cameraMode = CAMERA_NONE;
    static POINT ptMousePrev = {0};
    static POINT ptMouseCurrent = {0};
    static int mouseButtonsDown = 0;
    static float dx = 0.0f;
    static float dy = 0.0f;

    switch (msg)
    {
    case WM_LBUTTONDOWN:
        cameraMode = CAMERA_TRACK;
		g_click = true;
        ++mouseButtonsDown;
        SetCapture(hWnd);
        ptMousePrev.x = static_cast<int>(static_cast<short>(LOWORD(lParam)));
        ptMousePrev.y = static_cast<int>(static_cast<short>(HIWORD(lParam)));
        ClientToScreen(hWnd, &ptMousePrev);
        break;

    case WM_RBUTTONDOWN:
        cameraMode = CAMERA_ORBIT;
        ++mouseButtonsDown;
        SetCapture(hWnd);
        ptMousePrev.x = static_cast<int>(static_cast<short>(LOWORD(lParam)));
        ptMousePrev.y = static_cast<int>(static_cast<short>(HIWORD(lParam)));
        ClientToScreen(hWnd, &ptMousePrev);
        break;

    case WM_MBUTTONDOWN:
        cameraMode = CAMERA_DOLLY;
        ++mouseButtonsDown;
        SetCapture(hWnd);
        ptMousePrev.x = static_cast<int>(static_cast<short>(LOWORD(lParam)));
        ptMousePrev.y = static_cast<int>(static_cast<short>(HIWORD(lParam)));
        ClientToScreen(hWnd, &ptMousePrev);
        break;

    case WM_MOUSEMOVE:
        ptMouseCurrent.x = static_cast<int>(static_cast<short>(LOWORD(lParam)));
        ptMouseCurrent.y = static_cast<int>(static_cast<short>(HIWORD(lParam)));
        ClientToScreen(hWnd, &ptMouseCurrent);
		g_click = false;
        switch (cameraMode)
        {
        case CAMERA_TRACK:
            dx = static_cast<float>(ptMouseCurrent.x - ptMousePrev.x);
            dx *= MOUSE_TRACK_SPEED;

            dy = static_cast<float>(ptMouseCurrent.y - ptMousePrev.y);
            dy *= MOUSE_TRACK_SPEED;

            g_cameraPos[0] -= dx;
            g_cameraPos[1] += dy;

            g_targetPos[0] -= dx;
            g_targetPos[1] += dy;

            break;

        case CAMERA_DOLLY:
            dy = static_cast<float>(ptMouseCurrent.y - ptMousePrev.y);
            dy *= MOUSE_DOLLY_SPEED;

            g_cameraPos[2] -= dy;

            //if (g_cameraPos[2] < g_model.getRadius() + CAMERA_ZNEAR)
            //    g_cameraPos[2] = g_model.getRadius() + CAMERA_ZNEAR;

            //if (g_cameraPos[2] > CAMERA_ZFAR - g_model.getRadius())
            //    g_cameraPos[2] = CAMERA_ZFAR - g_model.getRadius();

            break;

        case CAMERA_ORBIT:
            dx = static_cast<float>(ptMouseCurrent.x - ptMousePrev.x);
            dx *= MOUSE_ORBIT_SPEED;

            dy = static_cast<float>(ptMouseCurrent.y - ptMousePrev.y);
            dy *= MOUSE_ORBIT_SPEED;

            g_heading += dx;
            g_pitch += dy;

            if (g_pitch > 90.0f)
                g_pitch = 90.0f;

            if (g_pitch < -90.0f)
                g_pitch = -90.0f;

            break;
        }

        ptMousePrev.x = ptMouseCurrent.x;
        ptMousePrev.y = ptMouseCurrent.y;
        break;

    case WM_LBUTTONUP:
		if(g_click){
			g_clickPosX = static_cast<int>(static_cast<short>(LOWORD(lParam)));
			g_clickPosY = g_windowHeight - static_cast<int>(static_cast<short>(HIWORD(lParam)));
			g_click = false;
		}
   case WM_RBUTTONUP:
    case WM_MBUTTONUP:
        if (--mouseButtonsDown <= 0)
        {
            mouseButtonsDown = 0;
            cameraMode = CAMERA_NONE;
            ReleaseCapture();
        }
        else
        {
            if (wParam & MK_LBUTTON)
                cameraMode = CAMERA_TRACK;
            else if (wParam & MK_RBUTTON)
                cameraMode = CAMERA_ORBIT;
            else if (wParam & MK_MBUTTON)
                cameraMode = CAMERA_DOLLY;
        }
        break;

    default:
        break;
    }
}

void ReadTextFileFromResource(const char *pResouceId, std::string &buffer)
{
    HMODULE hModule = GetModuleHandle(0);
    HRSRC hResource = FindResource(hModule, pResouceId, RT_RCDATA);

    if (hResource)
    {
        DWORD dwSize = SizeofResource(hModule, hResource);
        HGLOBAL hGlobal = LoadResource(hModule, hResource);

        if (hGlobal)
        {
            if (LPVOID pData = LockResource(hGlobal))
            {
                buffer.assign(reinterpret_cast<const char *>(pData), dwSize);
                UnlockResource(hGlobal);
            }
        }
    }
}

void ResetCamera()
{
    g_model.getCenter(g_targetPos[0], g_targetPos[1], g_targetPos[2]);

    g_cameraPos[0] = g_targetPos[0];
    g_cameraPos[1] = g_targetPos[1];
    g_cameraPos[2] = g_targetPos[2] + g_model.getRadius() + CAMERA_ZNEAR + 0.4f;

    g_pitch = 0.0f;
    g_heading = 0.0f;
}

void SetProcessorAffinity()
{
    // Assign the current thread to one processor. This ensures that timing
    // code runs on only one processor, and will not suffer any ill effects
    // from power management.
    //
    // Based on DXUTSetProcessorAffinity() function from the DXUT framework.

    DWORD_PTR dwProcessAffinityMask = 0;
    DWORD_PTR dwSystemAffinityMask = 0;
    HANDLE hCurrentProcess = GetCurrentProcess();

    if (!GetProcessAffinityMask(hCurrentProcess, &dwProcessAffinityMask, &dwSystemAffinityMask))
        return;

    if (dwProcessAffinityMask)
    {
        // Find the lowest processor that our process is allowed to run against.

        DWORD_PTR dwAffinityMask = (dwProcessAffinityMask & ((~dwProcessAffinityMask) + 1));

        // Set this as the processor that our thread must always run against.
        // This must be a subset of the process affinity mask.

        HANDLE hCurrentThread = GetCurrentThread();

        if (hCurrentThread != INVALID_HANDLE_VALUE)
        {
            SetThreadAffinityMask(hCurrentThread, dwAffinityMask);
            CloseHandle(hCurrentThread);
        }
    }

    CloseHandle(hCurrentProcess);
}

void ToggleFullScreen()
{
    static DWORD savedExStyle;
    static DWORD savedStyle;
    static RECT rcSaved;

    g_isFullScreen = !g_isFullScreen;

    if (g_isFullScreen)
    {
        // Moving to full screen mode.

        savedExStyle = GetWindowLong(g_hWnd, GWL_EXSTYLE);
        savedStyle = GetWindowLong(g_hWnd, GWL_STYLE);
        GetWindowRect(g_hWnd, &rcSaved);

        SetWindowLong(g_hWnd, GWL_EXSTYLE, 0);
        SetWindowLong(g_hWnd, GWL_STYLE, WS_POPUP | WS_CLIPCHILDREN | WS_CLIPSIBLINGS);
        SetWindowPos(g_hWnd, HWND_TOPMOST, 0, 0, 0, 0,
            SWP_NOMOVE | SWP_NOSIZE | SWP_FRAMECHANGED | SWP_SHOWWINDOW);

        g_windowWidth = GetSystemMetrics(SM_CXSCREEN);
        g_windowHeight = GetSystemMetrics(SM_CYSCREEN);

        SetWindowPos(g_hWnd, HWND_TOPMOST, 0, 0,
            g_windowWidth, g_windowHeight, SWP_SHOWWINDOW);
    }
    else
    {
        // Moving back to windowed mode.

        SetWindowLong(g_hWnd, GWL_EXSTYLE, savedExStyle);
        SetWindowLong(g_hWnd, GWL_STYLE, savedStyle);
        SetWindowPos(g_hWnd, HWND_NOTOPMOST, 0, 0, 0, 0,
            SWP_NOMOVE | SWP_NOSIZE | SWP_FRAMECHANGED | SWP_SHOWWINDOW);

        g_windowWidth = rcSaved.right - rcSaved.left;
        g_windowHeight = rcSaved.bottom - rcSaved.top;

        SetWindowPos(g_hWnd, HWND_NOTOPMOST, rcSaved.left, rcSaved.top,
            g_windowWidth, g_windowHeight, SWP_SHOWWINDOW);
    }
}

void UnloadModel()
{
    SetCursor(LoadCursor(0, IDC_WAIT));

    ModelTextures::iterator i = g_modelTextures.begin();

    while (i != g_modelTextures.end())
    {
        glDeleteTextures(1, &i->second);
        ++i;
    }

    g_modelTextures.clear();
    g_model.destroy();

    SetCursor(LoadCursor(0, IDC_ARROW));
    SetWindowText(g_hWnd, APP_TITLE);
}

void UpdateFrame(float elapsedTimeSec)
{
    UpdateFrameRate(elapsedTimeSec);
}

void UpdateFrameRate(float elapsedTimeSec)
{
    static float accumTimeSec = 0.0f;
    static int frames = 0;

    accumTimeSec += elapsedTimeSec;

    if (accumTimeSec > 1.0f)
    {
        g_framesPerSecond = frames;

        frames = 0;
        accumTimeSec = 0.0f;
    }
    else
    {
        ++frames;
    }
}

void BuildShaders()
{
	g_shaderAverageInit.attachVertexShader(SHADER_PATH "shade_vertex.glsl");
	g_shaderAverageInit.attachVertexShader(SHADER_PATH "wavg_init_vertex.glsl");
	g_shaderAverageInit.attachFragmentShader(SHADER_PATH "shade_fragment.glsl");
	g_shaderAverageInit.attachFragmentShader(SHADER_PATH "wavg_init_fragment.glsl");
	g_shaderAverageInit.link();

	g_shaderAverageFinal.attachVertexShader(SHADER_PATH "wavg_final_vertex.glsl");
	g_shaderAverageFinal.attachFragmentShader(SHADER_PATH "wavg_final_fragment.glsl");
	g_shaderAverageFinal.link();
/////////////////////////////////////////////////////
	g_shaderFrontInit.attachVertexShader(SHADER_PATH "shade_vertex.glsl");
	g_shaderFrontInit.attachVertexShader(SHADER_PATH "fp_init_vertex.glsl");
	g_shaderFrontInit.attachFragmentShader(SHADER_PATH "shade_fragment.glsl");
	g_shaderFrontInit.attachFragmentShader(SHADER_PATH "fp_init_fragment.glsl");
	g_shaderFrontInit.link();

	g_shaderFrontPeel.attachVertexShader(SHADER_PATH "shade_vertex.glsl");
	g_shaderFrontPeel.attachVertexShader(SHADER_PATH "fp_peel_vertex.glsl");
	g_shaderFrontPeel.attachFragmentShader(SHADER_PATH "shade_fragment.glsl");
	g_shaderFrontPeel.attachFragmentShader(SHADER_PATH "fp_common_variables.glsl");
	g_shaderFrontPeel.attachFragmentShader(SHADER_PATH "fp_coc_common.glsl");
	g_shaderFrontPeel.attachFragmentShader(SHADER_PATH "fp_peel_fragment.glsl");
	g_shaderFrontPeel.link();

	g_shaderFrontCalcCoc.attachVertexShader(SHADER_PATH "fp_final_vertex.glsl");
	g_shaderFrontCalcCoc.attachFragmentShader(SHADER_PATH "fp_common_variables.glsl");
	g_shaderFrontCalcCoc.attachFragmentShader(SHADER_PATH "fp_coc_common.glsl");
	g_shaderFrontCalcCoc.attachFragmentShader(SHADER_PATH "fp_calcCoc_fragment.glsl");
	g_shaderFrontCalcCoc.link();

	g_shaderFrontFinal.attachVertexShader(SHADER_PATH "fp_final_vertex.glsl");
	g_shaderFrontFinal.attachFragmentShader(SHADER_PATH "fp_common_variables.glsl");
	g_shaderFrontFinal.attachFragmentShader(SHADER_PATH "fp_final_fragment_new.glsl");
//	g_shaderFrontFinal.attachFragmentShader(SHADER_PATH "fp_filters_fragment.glsl");
	g_shaderFrontFinal.link();

	g_shaderFrontBackground.attachVertexShader(SHADER_PATH "fp_final_vertex.glsl");
	g_shaderFrontBackground.attachFragmentShader(SHADER_PATH "fp_background_fragment.glsl");
	g_shaderFrontBackground.link();
}
void InitAccumulationRenderTargets()
{
	glGenTextures(2, g_accumulationTexId);

	glBindTexture(GL_TEXTURE_RECTANGLE_ARB, g_accumulationTexId[0]);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_CLAMP);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_CLAMP);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA16F_ARB,
		g_windowWidth, g_windowHeight, 0, GL_RGBA, GL_FLOAT, NULL);

	glBindTexture(GL_TEXTURE_RECTANGLE_ARB, g_accumulationTexId[1]);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_CLAMP);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_CLAMP);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, GL_FLOAT_R32_NV,
		g_windowWidth, g_windowHeight, 0, GL_RGBA, GL_FLOAT, NULL);

	glGenFramebuffersEXT(1, &g_accumulationFboId);
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, g_accumulationFboId);
	glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT,
		GL_TEXTURE_RECTANGLE_ARB, g_accumulationTexId[0], 0);
	glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT1_EXT,
		GL_TEXTURE_RECTANGLE_ARB, g_accumulationTexId[1], 0);

	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
	//	CHECK_GL_ERRORS;
}
void InitFrontPeelingRenderTargets()
{

	glGenTextures(2, g_frontDepthTexId);
	glGenTextures(2, g_frontColorTexId);
	glGenFramebuffersEXT(2, g_frontFboId);

	for (int i = 0; i < 2; i++)
	{
		glBindTexture(GL_TEXTURE_RECTANGLE_ARB, g_frontDepthTexId[i]);
		glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_CLAMP);
		glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_CLAMP);
		glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, GL_DEPTH_COMPONENT32F_NV,
			g_windowWidth, g_windowHeight, 0, GL_DEPTH_COMPONENT, GL_FLOAT, NULL);

		glBindTexture(GL_TEXTURE_RECTANGLE_ARB, g_frontColorTexId[i]);
		glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_CLAMP);
		glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_CLAMP);
		glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA, g_windowWidth, g_windowHeight,
			0, GL_RGBA, GL_FLOAT, 0);

		glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, g_frontFboId[i]);
		glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT,
			GL_TEXTURE_RECTANGLE_ARB, g_frontDepthTexId[i], 0);
		glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT,
			GL_TEXTURE_RECTANGLE_ARB, g_frontColorTexId[i], 0);
	}

	glGenTextures(1, &g_frontCocTexId);
	glGenFramebuffersEXT(1, &g_frontCocFboId);

	glBindTexture(GL_TEXTURE_RECTANGLE_ARB, g_frontCocTexId);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_CLAMP);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_CLAMP);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA, g_windowWidth, g_windowHeight,
		0, GL_RGBA, GL_FLOAT, 0);

	glGenTextures(1, &g_frontRealDepthTexId);
	glBindTexture(GL_TEXTURE_RECTANGLE_ARB, g_frontRealDepthTexId);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_CLAMP);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_CLAMP);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA32F_ARB, g_windowWidth, g_windowHeight,
		0, GL_RGBA, GL_FLOAT, 0);

	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, g_frontCocFboId);
//	glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT,
//		GL_TEXTURE_RECTANGLE_ARB, g_frontCocTexId, 0);
	glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT,
		GL_TEXTURE_RECTANGLE_ARB, g_frontRealDepthTexId, 0);


	///////////////////////////              ColorBlender                   ///////////////////////////////
	glGenTextures(1, &g_frontColorBlenderTexId);
	glBindTexture(GL_TEXTURE_RECTANGLE_ARB, g_frontColorBlenderTexId);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_CLAMP);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_CLAMP);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA, g_windowWidth, g_windowHeight,
		0, GL_RGBA, GL_FLOAT, 0);

	glGenFramebuffersEXT(1, &g_frontColorBlenderFboId);
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, g_frontColorBlenderFboId);
	glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT,
		GL_TEXTURE_RECTANGLE_ARB, g_frontDepthTexId[0], 0);
	glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT,
		GL_TEXTURE_RECTANGLE_ARB, g_frontColorBlenderTexId, 0);


	//////////////////////////////            skybox      ////////////////////////////////////////////
	for(int i = 0; i < 6; ++i){
	char path[128];
	sprintf(path, "content//models//sky%d.bmp", i);
	Bitmap bitmap;
	bitmap.loadPicture(path);
	glGenTextures(1, &g_frontSkyboxTexId[i]);
	glBindTexture(GL_TEXTURE_2D, g_frontSkyboxTexId[i]);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
	gluBuild2DMipmaps(GL_TEXTURE_2D, 4, bitmap.width, bitmap.height,
		GL_BGRA_EXT, GL_UNSIGNED_BYTE, bitmap.getPixels());
	}

	float size[3]= {100, 100, 100};
	float pos[3]= {0, 0, 0};
	g_SkyBox.LoadTexture(g_frontSkyboxTexId);
	g_SkyBox.SetPosAndSize(pos, size);

	//glGenFramebuffersEXT(1, &g_frontBackgroundFboId);
	//glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, g_frontBackgroundFboId);
	//glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT,
	//	GL_TEXTURE_RECTANGLE_ARB, g_frontColorBlenderTexId, 0);
	//glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT1_EXT,
	//	GL_TEXTURE_RECTANGLE_ARB, g_frontColorTexId[1], 1);
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
}

void MakeFullScreenQuad()
{
	g_quadDisplayList = glGenLists(1);
	glNewList(g_quadDisplayList, GL_COMPILE);

	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();
	glLoadIdentity();
	gluOrtho2D(0.0, 1.0, 0.0, 1.0);
	glBegin(GL_QUADS);
	{
		glTexCoord2f(0.0f, 0.0f);
		glVertex2f(0.0, 0.0); 
		glTexCoord2f(1.0f, 0.0f);
		glVertex2f(1.0, 0.0);
		glTexCoord2f(1.0f, 1.0f);
		glVertex2f(1.0, 1.0);
		glTexCoord2f(0.0f, 1.0f);
		glVertex2f(0.0, 1.0);
	}
	glEnd();
	glPopMatrix();

	glEndList();
}
void RenderFrontToBackPeeling()
{

	DrawModel(0);
	int numLayers = 2;
	/*for (int layer = 1; layer < numLayers; layer++)*/ {
		currId = 1; //layer % 2;
		prevId = 1 - currId;

		DrawModel(1);

		//////////////////////////////////////////////////////////////////////////step 3
/*		glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, g_frontColorBlenderFboId);
		glDrawBuffer(g_drawBuffers[0]);

		glDisable(GL_DEPTH_TEST);
		//glEnable(GL_BLEND);

		//glBlendEquation(GL_FUNC_ADD);
		//glBlendFuncSeparate(GL_DST_ALPHA, GL_ONE,
		//	GL_ZERO, GL_ONE_MINUS_SRC_ALPHA);

		g_shaderFrontBlend.bind();
		g_shaderFrontBlend.bindTextureRECT("TempTex", g_frontColorTexId[currId], 0);
		glCallList(g_quadDisplayList);
		g_shaderFrontBlend.unbind();
*/
//		glDisable(GL_BLEND);
	}

	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, g_frontCocFboId);
	glDrawBuffers(2, g_drawBuffers);
	glDisable(GL_DEPTH_TEST);
	

//	glClearColor(1, 0, 0, 1);
//	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	g_shaderFrontCalcCoc.bind();
	g_shaderFrontCalcCoc.bindTextureRECT("DepthTex", g_frontDepthTexId[prevId], 0);
	g_shaderFrontCalcCoc.bindTextureRECT("DepthTex2", g_frontDepthTexId[currId], 1);
	g_shaderFrontCalcCoc.setUniform("focusX", (float*)&g_clickPosX, 1);
	g_shaderFrontCalcCoc.setUniform("focusY", (float*)&g_clickPosY, 1);
	float zFar = CAMERA_ZFAR;
	float zNear = CAMERA_ZNEAR;
	g_shaderFrontCalcCoc.setUniform("zFar", (float*)&zFar, 1);
	g_shaderFrontCalcCoc.setUniform("zNear", (float*)&zNear, 1);
	glCallList(g_quadDisplayList);
	g_shaderFrontCalcCoc.unbind();

	glDisable(GL_BLEND);

	//////////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////////
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
	glDrawBuffer(GL_BACK);
	glDisable(GL_DEPTH_TEST);

	g_shaderFrontFinal.bind();
	g_shaderFrontFinal.setUniform("BackgroundColor", g_backgroundColor, 3);
	g_shaderFrontFinal.setUniform("width", (float*)&g_windowWidth, 1);
	g_shaderFrontFinal.setUniform("height", (float*)&g_windowHeight, 1);
	g_shaderFrontFinal.setUniform("FocusX", (float*)&g_clickPosX, 1);
	g_shaderFrontFinal.setUniform("FocusY", (float*)&g_clickPosY, 1);
//	g_shaderFrontFinal.bindTextureRECT("CoCMap", /*g_frontColorTexId[currId]*/g_frontCocTexId, 0);
	g_shaderFrontFinal.bindTextureRECT("CocAndDepthMap", /*g_frontColorTexId[currId]*/g_frontRealDepthTexId, 0);
	g_shaderFrontFinal.bindTextureRECT("scene", /*g_frontColorTexId[currId]*/g_frontColorBlenderTexId, 1);
	g_shaderFrontFinal.bindTextureRECT("scene2", g_frontColorTexId[currId], 3);
	glCallList(g_quadDisplayList);
	g_shaderFrontFinal.unbind();

}
void RenderAverageColors()
{
	glDisable(GL_DEPTH_TEST);

	// ---------------------------------------------------------------------
	// 1. Accumulate Colors and Depth Complexity
	// ---------------------------------------------------------------------

	//glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, g_accumulationFboId);
	//glDrawBuffers(2, g_drawBuffers);

	//glClearColor(0, 0, 0, 0);
	//glClear(GL_COLOR_BUFFER_BIT);

	//glBlendEquationEXT(GL_FUNC_ADD);
	//glBlendFunc(GL_ONE, GL_ONE);
	//glEnable(GL_BLEND);

	//g_shaderAverageInit.bind();
	//g_shaderAverageInit.setUniform("Alpha", (float*)&g_opacity, 1);
	//DrawModel();
	//g_shaderAverageInit.unbind();

	//glDisable(GL_BLEND);

	DrawModel(0);

	// ---------------------------------------------------------------------
	// 2. Approximate Blending
	// ---------------------------------------------------------------------

	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
	glDrawBuffer(GL_BACK);

	g_shaderAverageFinal.bind();
	g_shaderAverageFinal.setUniform("BackgroundColor", g_backgroundColor, 3);
	g_shaderAverageFinal.bindTextureRECT("ColorTex0", g_accumulationTexId[0], 0);
	g_shaderAverageFinal.bindTextureRECT("ColorTex1", g_accumulationTexId[1], 1);
	glCallList(g_quadDisplayList);
	g_shaderAverageFinal.unbind();

	glEnable(GL_DEPTH_TEST);

}

void DrawModel(int step)
{
	const ModelOBJ::Mesh *pMesh = 0;
	const ModelOBJ::Material *pMaterial = 0;
	const ModelOBJ::Vertex *pVertices = 0;
	ModelTextures::const_iterator iter;
	GLuint texture = 0;

	preFor(step);
//	glBindBuffer(GL_ARRAY_BUFFER, g_vboId);
//	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, g_eboId);

	//	glEnable(GL_BLEND);
	//	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

	for (int i = 0; i < g_model.getNumberOfMeshes(); ++i)
	{
		pMesh = &g_model.getMesh(i);

		preModel(step, pMesh);
		if (g_model.hasPositions())
		{
			glEnableClientState(GL_VERTEX_ARRAY);
			glVertexPointer(3, GL_FLOAT, g_model.getVertexSize(),
				g_model.getVertexBuffer()->position);
		}

		if (g_model.hasTextureCoords())
		{
			glClientActiveTexture(GL_TEXTURE0);
			glEnableClientState(GL_TEXTURE_COORD_ARRAY);
			glTexCoordPointer(2, GL_FLOAT, g_model.getVertexSize(),
				g_model.getVertexBuffer()->texCoord);
		}

		if (g_model.hasNormals())
		{
			glEnableClientState(GL_NORMAL_ARRAY);
			glNormalPointer(GL_FLOAT, g_model.getVertexSize(),
				g_model.getVertexBuffer()->normal);
		}

		if (g_model.hasTangents())
		{
			glClientActiveTexture(GL_TEXTURE1);
			glEnableClientState(GL_TEXTURE_COORD_ARRAY);
			glTexCoordPointer(4, GL_FLOAT, g_model.getVertexSize(),
				g_model.getVertexBuffer()->tangent);
		}

		glDrawElements(GL_TRIANGLES, pMesh->triangleCount * 3, GL_UNSIGNED_INT,
			g_model.getIndexBuffer() + pMesh->startIndex);

		if (g_model.hasTangents())
		{
			glClientActiveTexture(GL_TEXTURE1);
			glDisableClientState(GL_TEXTURE_COORD_ARRAY);
		}

		if (g_model.hasNormals())
			glDisableClientState(GL_NORMAL_ARRAY);

		if (g_model.hasTextureCoords())
		{
			glClientActiveTexture(GL_TEXTURE0);
			glDisableClientState(GL_TEXTURE_COORD_ARRAY);
		}

		if (g_model.hasPositions())
			glDisableClientState(GL_VERTEX_ARRAY);

		postModel(step);
	}
	postFor(step);
}

void preFor(int step)
{
	switch(step){
	case 0:
		{
			glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, g_frontColorBlenderFboId);
			glDrawBuffer(g_drawBuffers[0]);

			glClearColor(0, 0, 0, 1);
			glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

			glEnable(GL_DEPTH_TEST);

			break;
		}
	case 1:
		{
			glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, g_frontFboId[currId]);
			glDrawBuffer(g_drawBuffers[0]);

			glClearColor(0, 0, 0, 0);
			glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

			glDisable(GL_BLEND);
			glEnable(GL_DEPTH_TEST);
		}
	default:
		break;
	}
	glDisable(GL_LIGHTING);
	g_SkyBox.Render();
	glEnable(GL_LIGHTING);

}
void postFor(int step)
{
	switch(step)
	{
	case 0:
		{
			break;
		}
	}
}

void preModel(int step, const ModelOBJ::Mesh *pMesh)
{
	const ModelOBJ::Material *pMaterial;
	const ModelOBJ::Vertex *pVertices;
	ModelTextures::const_iterator iter;
	GLuint texture = 0;

	pMaterial = pMesh->pMaterial;
	pVertices = g_model.getVertexBuffer();

	glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, pMaterial->ambient);
	glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, pMaterial->diffuse);
	glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, pMaterial->specular);
	glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, pMaterial->shininess * 128.0f);

	iter = g_modelTextures.find(pMaterial->colorMapFilename);

	if (iter != g_modelTextures.end())
		texture = iter->second;
	else
		texture = g_nullTexture;

	switch(step)
	{
	case 0:
		{

			g_shaderFrontInit.bind();
			g_shaderFrontInit.setUniform("Alpha", (float*)&g_opacity, 1);

			g_shaderFrontInit.bindTexture2D("srcTexture", texture, 0);
			break;
		}
	case 1:
		{
			g_shaderFrontPeel.bind();
			g_shaderFrontPeel.bindTextureRECT("DepthTex", g_frontDepthTexId[prevId], 1);
			g_shaderFrontPeel.bindTexture2D("srcTexture", texture, 0);
			g_shaderFrontPeel.setUniform("Alpha", (float*)&g_opacity, 1);
			g_shaderFrontPeel.setUniform("focusX", (float*)&g_clickPosX, 1);
			g_shaderFrontPeel.setUniform("focusY", (float*)&g_clickPosY, 1);
			float zFar = CAMERA_ZFAR;
			float zNear = CAMERA_ZNEAR;
			g_shaderFrontPeel.setUniform("zFar", (float*)&zFar, 1);
			g_shaderFrontPeel.setUniform("zNear", (float*)&zNear, 1);
		}
	default:
		break;
	}
}
void postModel(int step)
{
	switch(step)
	{
	case 0:
		{
			g_shaderFrontInit.unbind();
			break;
		}
	case 1:
		{
			g_shaderFrontPeel.unbind();
		}
	default:
		break;
	}
}