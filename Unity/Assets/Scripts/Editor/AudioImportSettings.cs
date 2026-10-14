using UnityEditor;
using UnityEngine;

namespace Blackjack.EditorTools
{
    /// <summary>
    /// The voice player reads raw samples to join words into one clip, which needs uncompressed
    /// "decompress on load" PCM — Unity's default for Android would be Vorbis. Applies to Resources/Sfx.
    /// </summary>
    public sealed class AudioImportSettings : AssetPostprocessor
    {
        private void OnPreprocessAudio()
        {
            if (!assetPath.StartsWith("Assets/Resources/Sfx/")) return;
            var importer = (AudioImporter)assetImporter;
            importer.forceToMono = true;
            importer.loadInBackground = false;
            var settings = new AudioImporterSampleSettings
            {
                loadType = AudioClipLoadType.DecompressOnLoad,
                compressionFormat = AudioCompressionFormat.PCM,
                sampleRateSetting = AudioSampleRateSetting.PreserveSampleRate,
            };
            importer.defaultSampleSettings = settings;
            importer.SetOverrideSampleSettings("Android", settings);
        }
    }
}
