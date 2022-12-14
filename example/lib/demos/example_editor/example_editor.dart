import 'dart:convert';

import 'package:example/demos/example_editor/_task.dart';
import 'package:example/logging.dart';
import 'package:example/model/content_audio.dart' as c;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

import '_example_document.dart';
import '_toolbar.dart';

import 'package:logging/logging.dart' as logging;

/// Example of a rich text editor.
///
/// This editor will expand in functionality as package
/// capabilities expand.
class ExampleEditor extends StatefulWidget {
  @override
  _ExampleEditorState createState() => _ExampleEditorState();
}

class _ExampleEditorState extends State<ExampleEditor> {
  final GlobalKey _docLayoutKey = GlobalKey();

  late Document _doc;
  late DocumentEditor _docEditor;
  late DocumentComposer _composer;
  late CommonEditorOperations _docOps;

  late FocusNode _editorFocusNode;

  late ScrollController _scrollController;

  final _darkBackground = const Color(0xFF222222);
  final _lightBackground = Colors.white;
  bool _isLight = true;

  OverlayEntry? _textFormatBarOverlayEntry;
  final _textSelectionAnchor = ValueNotifier<Offset?>(null);

  OverlayEntry? _imageFormatBarOverlayEntry;
  final _imageSelectionAnchor = ValueNotifier<Offset?>(null);
  bool isLoading = false;

  String _jsonDoc = '';
  Map<String, dynamic> valueMap = {};
  c.ContentJson? contentJson;
  String htmlParse = '';
  List<c.ChildrenContent> contents = [];
  List<String> htmlPas = [];

  final log = logging.Logger('MyClassName');

  // editor
  List<EditorModel> editorModels = [];


  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<String> getFileData() async {
    return await DefaultAssetBundle.of(context)
        .loadString('assets/test_doc.json');
  }

  List<c.ChildrenDocument> paragraphs = [];

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
    });
    paragraphs = [];
    _jsonDoc = await getFileData();
    valueMap = json.decode(_jsonDoc);
    contentJson = c.ContentJson.fromJson(valueMap);
    int index = 0;
    for (int j = 0;
        j < (contentJson?.content?.document?.children?.length ?? 0);
        j++) {
      c.ChildrenDocument? element =
          contentJson?.content?.document?.children![j];
      for (int i = 0;
          i <
              (contentJson?.content?.document?.children![j].children?.length ??
                  0);
          i++) {
        contentJson?.content?.document?.children![j].children![i].id =
            DocumentEditor.createNodeId();
      }
      paragraphs.add(element!);
      if (element.data?.id == null) {
        element.data?.id =
            "paragraph-content-${element.data?.start}-${DateTime.now().millisecondsSinceEpoch}";
      }
    }

    paragraphs.forEach((element) {
      GlobalKey _docLayoutKey = GlobalKey();
      Document _doc = createInitialDocument(element);
      DocumentEditor _docEditor =
      DocumentEditor(document: _doc as MutableDocument);
      DocumentComposer _composer = DocumentComposer(
          imeConfiguration:
          ImeConfiguration(keyboardActionButton: TextInputAction.done));
      CommonEditorOperations _docOps = CommonEditorOperations(
        editor: _docEditor,
        composer: _composer,
        documentLayoutResolver: () =>
        _docLayoutKey.currentState as DocumentLayout,
      );
      EditorModel editorModel = EditorModel(
          doc: _doc,
          docEditor: _docEditor,
          composer: _composer,
          docOps: _docOps,
          focusNode: FocusNode(),
          docLayoutKey: _docLayoutKey);
      editorModels.add(editorModel);
    });

    // _doc = createInitialDocument(paragraphs[0])
    //   ..addListener(_hideOrShowToolbar);
    // _docEditor = DocumentEditor(document: _doc as MutableDocument);
    // _composer = DocumentComposer(imeConfiguration: ImeConfiguration(
    //   keyboardActionButton: TextInputAction.done
    // ))..addListener(_hideOrShowToolbar);
    // _docOps = CommonEditorOperations(
    //   editor: _docEditor,
    //   composer: _composer,
    //   documentLayoutResolver: () =>
    //       _docLayoutKey.currentState as DocumentLayout,
    // );
    // _editorFocusNode = FocusNode();
    _scrollController = ScrollController()..addListener(_hideOrShowToolbar);

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    if (_textFormatBarOverlayEntry != null) {
      _textFormatBarOverlayEntry!.remove();
    }

    _scrollController.dispose();
    _editorFocusNode.dispose();
    _composer.dispose();
    super.dispose();
  }

  void _hideOrShowToolbar() {
    if (_gestureMode != DocumentGestureMode.mouse) {
      // We only add our own toolbar when using mouse. On mobile, a bar
      // is rendered for us.
      return;
    }

    final selection = _composer.selection;
    if (selection == null) {
      // Nothing is selected. We don't want to show a toolbar
      // in this case.
      _hideEditorToolbar();

      return;
    }
    if (selection.base.nodeId != selection.extent.nodeId) {
      // More than one node is selected. We don't want to show
      // a toolbar in this case.
      _hideEditorToolbar();
      _hideImageToolbar();

      return;
    }
    if (selection.isCollapsed) {
      // We only want to show the toolbar when a span of text
      // is selected. Therefore, we ignore collapsed selections.
      _hideEditorToolbar();
      _hideImageToolbar();

      return;
    }

    final selectedNode = _doc.getNodeById(selection.extent.nodeId);

    if (selectedNode is ImageNode) {
      appLog.fine("Showing image toolbar");
      // Show the editor's toolbar for image sizing.
      _showImageToolbar();
      _hideEditorToolbar();
      return;
    } else {
      // The currently selected content is not an image. We don't
      // want to show the image toolbar.
      _hideImageToolbar();
    }

    if (selectedNode is TextNode) {
      appLog.fine("Showing text format toolbar");
      // Show the editor's toolbar for text styling.
      _showEditorToolbar();
      _hideImageToolbar();
      return;
    } else {
      // The currently selected content is not a paragraph. We don't
      // want to show a toolbar in this case.
      _hideEditorToolbar();
    }
  }

  void _showEditorToolbar() {
    if (_textFormatBarOverlayEntry == null) {
      // Create an overlay entry to build the editor toolbar.
      // TODO: add an overlay to the Editor widget to avoid using the
      //       application overlay
      _textFormatBarOverlayEntry ??= OverlayEntry(builder: (context) {
        return EditorToolbar(
          anchor: _textSelectionAnchor,
          editorFocusNode: _editorFocusNode,
          editor: _docEditor,
          composer: _composer,
          closeToolbar: _hideEditorToolbar,
        );
      });

      // Display the toolbar in the application overlay.
      final overlay = Overlay.of(context)!;
      overlay.insert(_textFormatBarOverlayEntry!);
    }

    // Schedule a callback after this frame to locate the selection
    // bounds on the screen and display the toolbar near the selected
    // text.
    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
      if (_textFormatBarOverlayEntry == null) {
        return;
      }

      final docBoundingBox = (_docLayoutKey.currentState as DocumentLayout)
          .getRectForSelection(
              _composer.selection!.base, _composer.selection!.extent)!;
      final docBox =
          _docLayoutKey.currentContext!.findRenderObject() as RenderBox;
      final overlayBoundingBox = Rect.fromPoints(
        docBox.localToGlobal(docBoundingBox.topLeft),
        docBox.localToGlobal(docBoundingBox.bottomRight),
      );

      _textSelectionAnchor.value = overlayBoundingBox.topCenter;
    });
  }

  void _hideEditorToolbar() {
    // Null out the selection anchor so that when it re-appears,
    // the bar doesn't momentarily "flash" at its old anchor position.
    _textSelectionAnchor.value = null;

    if (_textFormatBarOverlayEntry != null) {
      // Remove the toolbar overlay and null-out the entry.
      // We null out the entry because we can't query whether
      // or not the entry exists in the overlay, so in our
      // case, null implies the entry is not in the overlay,
      // and non-null implies the entry is in the overlay.
      _textFormatBarOverlayEntry!.remove();
      _textFormatBarOverlayEntry = null;

      // Ensure that focus returns to the editor.
      //
      // I tried explicitly unfocus()'ing the URL textfield
      // in the toolbar but it didn't return focus to the
      // editor. I'm not sure why.
      _editorFocusNode.requestFocus();
    }
  }

  DocumentGestureMode get _gestureMode {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return DocumentGestureMode.android;
      case TargetPlatform.iOS:
        return DocumentGestureMode.iOS;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return DocumentGestureMode.mouse;
    }
  }

  bool get _isMobile => _gestureMode != DocumentGestureMode.mouse;

  DocumentInputSource get _inputSource {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return DocumentInputSource.ime;
      // return DocumentInputSource.keyboard;
    }
  }

  void _cut() => _docOps.cut();

  void _copy() => _docOps.copy();

  void _paste() => _docOps.paste();

  void _selectAll() => _docOps.selectAll();

  void _showImageToolbar() {
    if (_imageFormatBarOverlayEntry == null) {
      // Create an overlay entry to build the image toolbar.
      _imageFormatBarOverlayEntry ??= OverlayEntry(builder: (context) {
        return ImageFormatToolbar(
          anchor: _imageSelectionAnchor,
          composer: _composer,
          setWidth: (nodeId, width) {
            final node = _doc.getNodeById(nodeId)!;
            final currentStyles =
                SingleColumnLayoutComponentStyles.fromMetadata(node);
            SingleColumnLayoutComponentStyles(
              width: width,
              padding: currentStyles.padding,
            ).applyTo(node);
          },
          closeToolbar: _hideImageToolbar,
        );
      });

      // Display the toolbar in the application overlay.
      final overlay = Overlay.of(context)!;
      overlay.insert(_imageFormatBarOverlayEntry!);
    }

    // Schedule a callback after this frame to locate the selection
    // bounds on the screen and display the toolbar near the selected
    // text.
    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
      if (_imageFormatBarOverlayEntry == null) {
        return;
      }

      final docBoundingBox = (_docLayoutKey.currentState as DocumentLayout)
          .getRectForSelection(
              _composer.selection!.base, _composer.selection!.extent)!;
      final docBox =
          _docLayoutKey.currentContext!.findRenderObject() as RenderBox;
      final overlayBoundingBox = Rect.fromPoints(
        docBox.localToGlobal(docBoundingBox.topLeft),
        docBox.localToGlobal(docBoundingBox.bottomRight),
      );

      _imageSelectionAnchor.value = overlayBoundingBox.center;
    });
  }

  void _hideImageToolbar() {
    // Null out the selection anchor so that when the bar re-appears,
    // it doesn't momentarily "flash" at its old anchor position.
    _imageSelectionAnchor.value = null;

    if (_imageFormatBarOverlayEntry != null) {
      // Remove the image toolbar overlay and null-out the entry.
      // We null out the entry because we can't query whether
      // or not the entry exists in the overlay, so in our
      // case, null implies the entry is not in the overlay,
      // and non-null implies the entry is in the overlay.
      _imageFormatBarOverlayEntry!.remove();
      _imageFormatBarOverlayEntry = null;

      // Ensure that focus returns to the editor.
      _editorFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Container(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        : Stack(
            children: [
              Column(
                children: [
                  SizedBox(
                    height: 100,
                  ),
                  Expanded(
                    child: _buildBody(context),
                  ),
                  // if (_isMobile) _buildMountedToolbar(),
                ],
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: _buildLightAndDarkModeToggle(),
              ),
            ],
          );
  }

  Widget _buildBody(BuildContext buildContext) {
    return Container(
        child: ListView.separated(
          itemCount: paragraphs.length,
          // physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(bottom: 10, left: 20, right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    height: 4,
                  ),
                  _buildEditor(editorModels[index]),
                ],
              ),
            );
          },
          separatorBuilder: (context, index) {
            return SizedBox(
              height: 10,
              child: Divider(),
            );
          },
        ));
  }

  Widget _buildLightAndDarkModeToggle() {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0, bottom: 16.0),
      child: FloatingActionButton(
        backgroundColor: _isLight ? _darkBackground : _lightBackground,
        foregroundColor: _isLight ? _lightBackground : _darkBackground,
        elevation: 5,
        onPressed: () {
          setState(() {
            _isLight = !_isLight;
          });
          print(_doc);

          for (int i = 0; i < _doc.nodes.length; i++) {
            ParagraphNode paragraphNode = _doc.nodes[i] as ParagraphNode;
            for (int j = 0; j < (paragraphs[0].children?.length ?? 0); j++) {
              if (paragraphs[0].children![j].id != paragraphNode.id) {
                paragraphs[0].children![j].text = '';
              }
            }
          }
          for (int i = 0; i < _doc.nodes.length; i++) {
            ParagraphNode paragraphNode = _doc.nodes[i] as ParagraphNode;
            for (int j = 0; j < (paragraphs[0].children?.length ?? 0); j++) {
              if (paragraphs[0].children![j].id == paragraphNode.id) {
                paragraphs[0].children![j].text = paragraphNode.text.text;
              }
            }
          }

          log.info(paragraphs.toString());
          editorDocLog.info('test');

          print(paragraphs.toString());
        },
        child: _isLight
            ? const Icon(
                Icons.dark_mode,
              )
            : const Icon(
                Icons.light_mode,
              ),
      ),
    );
  }

  Widget _buildEditor(EditorModel editorModel) {
    return ColoredBox(
      color: _isLight ? _lightBackground : _darkBackground,
      child: SuperEditor(
        editor: editorModel.docEditor,
        composer: editorModel.composer,
        focusNode: editorModel.focusNode,
        // scrollController: _scrollController,
        documentLayoutKey: editorModel.docLayoutKey,
        documentOverlayBuilders: [
          DefaultCaretOverlayBuilder(
            CaretStyle()
                .copyWith(color: _isLight ? Colors.black : Colors.redAccent),
          ),
        ],
        selectionStyle: _isLight
            ? defaultSelectionStyle
            : SelectionStyles(
                selectionColor: Colors.red.withOpacity(0.3),
              ),
        stylesheet: defaultStylesheet.copyWith(
          addRulesAfter: [
            if (!_isLight) ..._darkModeStyles,
            taskStyles,
          ],
        ),
        componentBuilders: [
          ...defaultComponentBuilders,
          TaskComponentBuilder(editorModel.docEditor),
        ],
        gestureMode: _gestureMode,
        inputSource: _inputSource,
        // keyboardActions: _inputSource == DocumentInputSource.ime
        //     ? defaultImeKeyboardActions
        //     : defaultKeyboardActions,
        androidToolbarBuilder: (_) => AndroidTextEditingFloatingToolbar(
          onCutPressed: _cut,
          onCopyPressed: _copy,
          onPastePressed: _paste,
          onSelectAllPressed: _selectAll,
        ),
        iOSToolbarBuilder: (_) => IOSTextEditingFloatingToolbar(
          onCutPressed: _cut,
          onCopyPressed: _copy,
          onPastePressed: _paste,
        ),
        onInputAction: (action){
          print("Input action $action");
        },
        onCheckChanged: (changed){
          print("Check changed $changed");
        },
      ),
    );
  }

  Widget _buildMountedToolbar() {
    return MultiListenableBuilder(
      listenables: <Listenable>{
        _doc,
        _composer.selectionNotifier,
      },
      builder: (_) {
        final selection = _composer.selection;

        if (selection == null) {
          return const SizedBox();
        }

        return KeyboardEditingToolbar(
          document: _doc,
          composer: _composer,
          commonOps: _docOps,
        );
      },
    );
  }
}

// Makes text light, for use during dark mode styling.
final _darkModeStyles = [
  StyleRule(
    BlockSelector.all,
    (doc, docNode) {
      return {
        "textStyle": const TextStyle(
          color: Color(0xFFCCCCCC),
        ),
      };
    },
  ),
  StyleRule(
    const BlockSelector("header1"),
    (doc, docNode) {
      return {
        "textStyle": const TextStyle(
          color: Color(0xFF888888),
        ),
      };
    },
  ),
  StyleRule(
    const BlockSelector("header2"),
    (doc, docNode) {
      return {
        "textStyle": const TextStyle(
          color: Color(0xFF888888),
        ),
      };
    },
  ),
];

class EditorModel {
  final Document doc;
  final DocumentEditor docEditor;
  final DocumentComposer composer;
  final CommonEditorOperations docOps;
  final FocusNode focusNode;
  final GlobalKey? docLayoutKey;

  EditorModel(
      {required this.doc,
        required this.docEditor,
        required this.composer,
        required this.docOps,
        required this.focusNode,
        this.docLayoutKey});
}
