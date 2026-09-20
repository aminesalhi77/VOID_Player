cmake_minimum_required(VERSION 3.21)
project(VOID VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS
    Core Gui Widgets Quick QuickControls2 Multimedia Svg Sql
)

find_package(PkgConfig REQUIRED)
pkg_check_modules(TAGLIB REQUIRED taglib)

qt_standard_project_setup()
qt_policy(SET QTP0001 NEW)
qt_policy(SET QTP0004 NEW)

qt_add_executable(void
    src/main.cpp
    src/library/Track.h
    src/library/Library.h
    src/library/Library.cpp
    src/library/LibraryDb.h
    src/library/LibraryDb.cpp
    src/metadata/TagReader.h
    src/metadata/TagReader.cpp
    src/models/TrackModel.h
    src/models/TrackModel.cpp
    src/player/Playback.h
    src/player/AudioAnalyzer.h
    src/player/AudioAnalyzer.cpp
    src/player/LyricsFetcher.h
    src/player/LyricsFetcher.cpp
    src/player/Playback.cpp
    src/player/ArtistImageFetcher.h
    src/player/ArtistImageFetcher.cpp
)
# Register Theme.qml as a QML singleton
set_source_files_properties(qml/theme/Theme.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
)
qt_add_qml_module(void
    URI Void
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/components/AlbumDetail.qml
        qml/components/ArtistDetail.qml
        qml/components/LyricsPanel.qml
        qml/components/LyricsSyncDialog.qml
    RESOURCES
    qml/theme/Theme.qml
        qml/assets/icons/disc.svg
        qml/assets/icons/bars.svg
        qml/assets/background/bg.png
        qml/assets/background/vortex.png
        qml/components/FocusKiller.qml
)

target_include_directories(void PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${TAGLIB_INCLUDE_DIRS}
)

target_link_libraries(void PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Widgets
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Multimedia
    Qt6::Svg
    Qt6::Sql
    ${TAGLIB_LIBRARIES}
)

set_target_properties(void PROPERTIES
    WIN32_EXECUTABLE TRUE
    MACOSX_BUNDLE TRUE
)