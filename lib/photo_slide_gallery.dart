import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class PhotoSlideGallery extends StatefulWidget {
  /// Construct a gallery with static items through a list of [PhotoViewGalleryPageOptions].
  const PhotoSlideGallery({
    Key? key,
    required this.pageOptions,
    this.loadingBuilder,
    this.backgroundDecoration,
    this.gaplessPlayback = false,
    this.reverse = false,
    this.pageController,
    this.onPageChanged,
    this.scaleStateChangedCallback,
    this.enableRotation = false,
    this.scrollPhysics,
    this.scrollDirection = Axis.horizontal,
    this.customSize,
    this.previewOptions,
    this.backgroundColor = Colors.black,
    this.previewSize = const Size.fromHeight(100),
    this.previewPadding = const EdgeInsets.only(left: 10, bottom: 10),
    this.initialPage = 0,
    this.animationDuration = const Duration(milliseconds: 200),
    this.onDoubleTap,
  })  : itemCount = null,
        builder = null,
        super(key: key);

  /// Construct a gallery with dynamic items.
  ///
  /// The builder must return a [PhotoViewGalleryPageOptions].
  const PhotoSlideGallery.builder({
    Key? key,
    required this.itemCount,
    required this.builder,
    this.loadingBuilder,
    this.backgroundDecoration,
    this.gaplessPlayback = false,
    this.reverse = false,
    this.pageController,
    this.onPageChanged,
    this.scaleStateChangedCallback,
    this.enableRotation = false,
    this.scrollPhysics,
    this.scrollDirection = Axis.horizontal,
    this.customSize,
    this.previewOptions,
    this.backgroundColor = Colors.black,
    this.previewSize = const Size.fromHeight(100),
    this.previewPadding = const EdgeInsets.only(left: 10, bottom: 10),
    this.initialPage = 0,
    this.animationDuration = const Duration(milliseconds: 200),
    this.onDoubleTap,
  })  : pageOptions = null,
        assert(itemCount != null),
        assert(builder != null),
        super(key: key);

  /// A list of options to describe the items in the gallery
  final List<PhotoViewGalleryPageOptions>? pageOptions;

  ///Preview option to build preview item
  final List<PhotoPreviewOptions>? previewOptions;

  /// The count of items in the gallery, only used when constructed via [PhotoViewGallery.builder]
  final int? itemCount;

  /// Called to build items for the gallery when using [PhotoViewGallery.builder]
  final PhotoViewGalleryBuilder? builder;

  /// [ScrollPhysics] for the internal [PageView]
  final ScrollPhysics? scrollPhysics;

  /// Mirror to [PhotoView.loadingBuilder]
  final LoadingBuilder? loadingBuilder;

  /// Mirror to [PhotoView.backgroundDecoration]
  final BoxDecoration? backgroundDecoration;

  /// Mirror to [PhotoView.gaplessPlayback]
  final bool gaplessPlayback;

  /// Mirror to [PageView.reverse]
  final bool reverse;

  /// An object that controls the [PageView] inside [PhotoViewGallery]
  final PageController? pageController;

  /// An callback to be called on a page change
  final PhotoViewGalleryPageChangedCallback? onPageChanged;

  /// Mirror to [PhotoView.scaleStateChangedCallback]
  final ValueChanged<PhotoViewScaleState>? scaleStateChangedCallback;

  /// Mirror to [PhotoView.enableRotation]
  final bool enableRotation;

  /// Mirror to [PhotoView.customSize]
  final Size? customSize;

  final Size previewSize;

  final EdgeInsets previewPadding;

  /// The axis along which the [PageView] scrolls. Mirror to [PageView.scrollDirection]
  final Axis scrollDirection;

  final Color backgroundColor;

  ///init page of photos
  final int initialPage;

  ///animation transition photo page duration
  final Duration animationDuration;

  ///call back when double click to photo view
  final GestureDoubleTapCallback? onDoubleTap;

  bool get _isBuilder => builder != null;

  @override
  State<StatefulWidget> createState() {
    return _PhotoSlideGalleryState();
  }
}

class _PhotoSlideGalleryState extends State<PhotoSlideGallery>
    with SingleTickerProviderStateMixin {
  late PageController _controller = widget.pageController ?? PageController();

  ///animation to visible or invisible preview photos when zoom
  late AnimationController _animationController;

  late PhotoGalleryController _photoGalleryController;

  late Animation<double> _opacityAnimation;
  late Animation<double> _sizeAnimation;

  ///use to lock when scroll choose photo preview
  bool _animated = false;

  bool isInteger(num value) => value is int || value == value.roundToDouble();

  @override
  void initState() {
    _currentPage = widget.initialPage;
    _controller = widget.pageController ??
        PageController(initialPage: widget.initialPage);
    _photoGalleryController = PhotoGalleryController(page: widget.initialPage);
    _photoGalleryController.changePage(widget.initialPage);
    _animationController =
        AnimationController(vsync: this, duration: widget.animationDuration);
    _opacityAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.linear);
    _opacityAnimation =
        Tween<double>(begin: 1.0, end: 0.0).animate(_opacityAnimation);
    _sizeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.linear);
    _sizeAnimation =
        Tween<double>(begin: 1.0, end: 0.0).animate(_sizeAnimation);

    _controller.addListener(() {
      if (_animated) {
        if (_controller.page == _currentPage) {
          _animated = false;
        }
      } else {
        if (isInteger(_controller.page ?? actualPage)) {
          _animationController.reverse();
          _currentPage = actualPage;
          _photoGalleryController.changePage(actualPage);
        }
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    if (widget.pageController == null) {
      _controller.dispose();
    }
    _animationController.dispose();
    _photoGalleryController.dispose();
    super.dispose();
  }

  void scaleStateChangedCallback(PhotoViewScaleState scaleState) {
    if (widget.scaleStateChangedCallback != null) {
      widget.scaleStateChangedCallback!(scaleState);
    }
  }

  int get actualPage {
    return _controller.hasClients ? _controller.page!.floor() : 0;
  }

  int _currentPage = 0;

  int get itemCount {
    if (widget._isBuilder) {
      return widget.itemCount!;
    }
    return widget.pageOptions!.length;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: PhotoViewGestureDetectorScope(
                  axis: widget.scrollDirection,
                  child: PageView.builder(
                    reverse: widget.reverse,
                    controller: _controller,
                    onPageChanged: widget.onPageChanged,
                    itemCount: itemCount,
                    itemBuilder: _buildItem,
                    scrollDirection: widget.scrollDirection,
                    physics: widget.scrollPhysics,
                  ),
                ),
              ),
              SizeTransition(
                sizeFactor: _sizeAnimation,
                child: FadeTransition(
                  opacity: _opacityAnimation,
                  child: Padding(
                    padding: widget.previewPadding,
                    child: SizedBox(
                      height: widget.previewSize.height,
                      width: widget.previewSize.width,
                      child: _buildPreviewPhotos(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Positioned(
          //   bottom: 0,
          //   left: 0,
          //   right: 0,
          //   child: SizeTransition(
          //     sizeFactor: _sizeAnimation,
          //     child: FadeTransition(
          //       opacity: _opacityAnimation,
          //       child: Padding(
          //         padding: widget.previewPadding,
          //         child: SizedBox(
          //           height: widget.previewSize.height,
          //           width: widget.previewSize.width,
          //           child: _buildPreviewPhotos(),
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final pageOption = _buildPageOption(context, index);
    final isCustomChild = pageOption.child != null;

    final PhotoView photoView = isCustomChild
        ? PhotoView.customChild(
            key: ObjectKey(index),
            child: pageOption.child,
            childSize: pageOption.childSize,
            backgroundDecoration: widget.backgroundDecoration,
            controller: pageOption.controller,
            scaleStateController: pageOption.scaleStateController,
            customSize: widget.customSize,
            heroAttributes: pageOption.heroAttributes,
            scaleStateChangedCallback: scaleStateChangedCallback,
            enableRotation: widget.enableRotation,
            initialScale: pageOption.initialScale,
            minScale: pageOption.minScale,
            maxScale: pageOption.maxScale,
            scaleStateCycle: pageOption.scaleStateCycle,
            onTapUp: (
              BuildContext context,
              TapUpDetails details,
              PhotoViewControllerValue controllerValue,
            ) {
              pageOption.onTapUp?.call(context, details, controllerValue);
              _animationController.reverse();
            },
            onDoubleTap: () {
              if (!(_animationController.isCompleted ||
                  _animationController.isAnimating)) {
                _animationController.forward();
              }
            },
            onTapDown: pageOption.onTapDown,
            gestureDetectorBehavior: pageOption.gestureDetectorBehavior,
            tightMode: pageOption.tightMode,
            filterQuality: pageOption.filterQuality,
            basePosition: pageOption.basePosition,
            disableGestures: pageOption.disableGestures,
            onScaleStart: (BuildContext context, ScaleStartDetails details,
                PhotoViewControllerValue controllerValue) {
              pageOption.onScaleStart?.call(context, details, controllerValue);
              if (!(_animationController.isCompleted ||
                  _animationController.isAnimating)) {
                _animationController.forward();
              }
            },
            onScaleUpdate: (
              BuildContext context,
              ScaleUpdateDetails details,
              PhotoViewControllerValue controllerValue,
            ) {
              pageOption.onScaleUpdate?.call(context, details, controllerValue);
            },
            onScaleEnd: (
              BuildContext context,
              ScaleEndDetails details,
              PhotoViewControllerValue controllerValue,
            ) {
              pageOption.onScaleEnd?.call(context, details, controllerValue);
              if (_animationController.isCompleted ||
                  _animationController.isAnimating) {
                _animationController.reverse();
              }
            },
          )
        : PhotoView(
            key: ObjectKey(index),
            imageProvider: pageOption.imageProvider,
            loadingBuilder: widget.loadingBuilder,
            backgroundDecoration: widget.backgroundDecoration,
            controller: pageOption.controller,
            scaleStateController: pageOption.scaleStateController,
            customSize: widget.customSize,
            gaplessPlayback: widget.gaplessPlayback,
            heroAttributes: pageOption.heroAttributes,
            scaleStateChangedCallback: scaleStateChangedCallback,
            enableRotation: widget.enableRotation,
            initialScale: pageOption.initialScale,
            minScale: pageOption.minScale,
            maxScale: pageOption.maxScale,
            scaleStateCycle: pageOption.scaleStateCycle,
            onTapUp: (
              BuildContext context,
              TapUpDetails details,
              PhotoViewControllerValue controllerValue,
            ) {
              pageOption.onTapUp?.call(context, details, controllerValue);
              _animationController.reverse();
            },
            onTapDown: pageOption.onTapDown,
            gestureDetectorBehavior: pageOption.gestureDetectorBehavior,
            tightMode: pageOption.tightMode,
            filterQuality: pageOption.filterQuality,
            basePosition: pageOption.basePosition,
            disableGestures: pageOption.disableGestures,
            errorBuilder: pageOption.errorBuilder,
            onScaleStart: (BuildContext context, ScaleStartDetails details,
                PhotoViewControllerValue controllerValue) {
              pageOption.onScaleStart?.call(context, details, controllerValue);
              if (!(_animationController.isCompleted ||
                  _animationController.isAnimating)) {
                _animationController.forward();
              }
            },
            onScaleUpdate: (
              BuildContext context,
              ScaleUpdateDetails details,
              PhotoViewControllerValue controllerValue,
            ) {
              pageOption.onScaleUpdate?.call(context, details, controllerValue);
            },
            onScaleEnd: (
              BuildContext context,
              ScaleEndDetails details,
              PhotoViewControllerValue controllerValue,
            ) {
              pageOption.onScaleEnd?.call(context, details, controllerValue);
            },
            onDoubleTap: () {
              if (!(_animationController.isCompleted ||
                  _animationController.isAnimating)) {
                _animationController.forward();
              }
            },
          );

    return ClipRect(
      child: photoView,
    );
  }

  Widget _buildPreviewPhotos() {
    return _PreviewGallery(
      itemCount: itemCount,
      previewOptions: widget.previewOptions,
      photoGalleryController: _photoGalleryController,
      backgroundColor: widget.backgroundColor,
      animationDuration: widget.animationDuration,
      onPageChanged: (int page) {
        _animated = true;
        _currentPage = _photoGalleryController.page;
        widget.onPageChanged?.call(_photoGalleryController.page);
        _photoGalleryController.changePage(page);
        _controller.animateToPage(page,
            duration: widget.animationDuration, curve: Curves.linear);
      },
    );
  }

  PhotoViewGalleryPageOptions _buildPageOption(
      BuildContext context, int index) {
    if (widget._isBuilder) {
      return widget.builder!(context, index);
    }
    return widget.pageOptions![index];
  }
}

///[PreviewGallery] widget use for [PhotoSlideGallery] to preview all photos
class _PreviewGallery extends StatefulWidget {
  const _PreviewGallery({
    Key? key,
    this.previewOptions,
    this.builder,
    required this.itemCount,
    this.onPageChanged,
    this.scrollPhysics,
    required this.photoGalleryController,
    this.backgroundColor = Colors.black,
    this.animationDuration = const Duration(milliseconds: 200),
  }) : super(key: key);

  @override
  _PreviewGalleryState createState() => _PreviewGalleryState();

  ///Preview option to build preview item
  final List<PhotoPreviewOptions>? previewOptions;

  /// The count of items in the preview gallery, only used when constructed via [PreviewGalleryBuilder.builder]
  final int itemCount;

  /// Called to build items for the preview gallery when using [PreviewGalleryBuilder.builder]
  final PreviewGalleryBuilder? builder;

  /// [ScrollPhysics] for the internal [PageView]
  final ScrollPhysics? scrollPhysics;

  /// An callback to be called on a page change
  final PhotoViewGalleryPageChangedCallback? onPageChanged;

  final PhotoGalleryController photoGalleryController;

  final Color backgroundColor;

  final Duration animationDuration;
}

class _PreviewGalleryState extends State<_PreviewGallery> {
  final AutoScrollController _autoScrollController = AutoScrollController();

  int _currentPage = 0;

  @override
  void initState() {
    _currentPage = widget.photoGalleryController.page;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _autoScrollController.scrollToIndex(
              _currentPage,
              duration: widget.animationDuration,
            ));

    widget.photoGalleryController.addListener(() {
      if (_currentPage != widget.photoGalleryController.page) {
        setState(() {
          _currentPage = widget.photoGalleryController.page;
        });
        _autoScrollController.scrollToIndex(
          _currentPage,
          duration: widget.animationDuration,
        );
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final double width = widget.itemCount *
        (widget.previewOptions?.first.childSize?.width ?? 40);

    final MainAxisAlignment mainAxisAlignment =
        width > MediaQuery.of(context).size.width
            ? MainAxisAlignment.start
            : MainAxisAlignment.center;

    if (width <= MediaQuery.of(context).size.width) {
      return Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(
          widget.itemCount,
          (index) => _buildItem(context, index),
        ),
      );
    }

    return SingleChildScrollView(
      controller: _autoScrollController,
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: width,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(
            widget.itemCount,
            (index) => _buildItem(context, index),
          ),
        ),
      ),
    );

    // return Container(
    //   color: Colors.black,
    //   child: ListView.separated(
    //     controller: _autoScrollController,
    //     itemBuilder: _buildItem,
    //     separatorBuilder: (BuildContext context, int index) {
    //       return const SizedBox(width: 10);
    //     },
    //     itemCount: itemCount,
    //     scrollDirection: Axis.horizontal,
    //   ),
    // );
  }

  int get itemCount {
    if (widget.builder != null) {
      return widget.itemCount;
    }
    return widget.previewOptions!.length;
  }

  PhotoPreviewOptions _buildPageOption(BuildContext context, int index) {
    return widget.previewOptions![index];
  }

  Widget? _buildSelectedItem() {
    return widget.previewOptions?[_currentPage].selectedBuilder
        ?.call(context, _currentPage);
  }

  Widget _buildItem(BuildContext context, int index) {
    final pageOption = _buildPageOption(context, index);
    final isCustomChild = pageOption.builder != null;

    final Widget previewPhoto = isCustomChild
        ? pageOption.builder!(context, index)
        : Container(
            width: widget.previewOptions?[index].childSize?.width ?? 100,
            height: widget.previewOptions?[index].childSize?.width ?? 100,
            margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              image: DecorationImage(
                image: pageOption.imageProvider!,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          );

    return AutoScrollTag(
      key: ValueKey(index),
      index: index,
      controller: _autoScrollController,
      child: InkWell(
        child: _currentPage == index
            ? _buildSelectedItem() ?? previewPhoto
            : previewPhoto,
        onTap: () {
          setState(() {
            _currentPage = index;
          });

          widget.photoGalleryController.changePage(index);
          widget.onPageChanged?.call(index);
          _autoScrollController.scrollToIndex(
            index,
            duration: widget.animationDuration,
          );
        },
      ),
    );
  }
}
