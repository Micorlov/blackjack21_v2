using System.IO;
using UnityEditor;
using UnityEngine;

namespace Blackjack.EditorTools
{
    /// <summary>One-shot project setup, run in batch mode: <c>-executeMethod Blackjack.EditorTools.ProjectSetup.Run</c>.</summary>
    public static class ProjectSetup
    {
        private const string TmpPackage =
            "Packages/com.unity.ugui/Package Resources/TMP Essential Resources.unitypackage";

        public static void Run()
        {
            if (Directory.Exists("Assets/TextMesh Pro/Resources"))
            {
                Debug.Log("TMP essentials already imported");
                EditorApplication.Exit(0);
                return;
            }
            // The import is queued; exit only once Unity reports it finished.
            AssetDatabase.importPackageCompleted += _ => { Debug.Log("ProjectSetup done"); EditorApplication.Exit(0); };
            AssetDatabase.importPackageFailed += (_, error) => { Debug.LogError("Import failed: " + error); EditorApplication.Exit(1); };
            ImportTmpEssentials();
        }

        /// <summary>Re-imports the audio so <see cref="AudioImportSettings"/> applies: <c>-executeMethod Blackjack.EditorTools.ProjectSetup.ReimportAudio</c>.</summary>
        public static void ReimportAudio()
        {
            AssetDatabase.ImportAsset("Assets/Resources/Sfx", ImportAssetOptions.ImportRecursive | ImportAssetOptions.ForceUpdate);
            AssetDatabase.SaveAssets();
            Debug.Log("Audio reimported");
            EditorApplication.Exit(0);
        }

        private static void ImportTmpEssentials()
        {
            var path = Path.GetFullPath(TmpPackage);
            if (!File.Exists(path))
            {
                Debug.LogError("TMP essentials package not found at " + path);
                EditorApplication.Exit(1);
                return;
            }
            AssetDatabase.ImportPackage(path, false);
            AssetDatabase.Refresh();
        }
    }
}
