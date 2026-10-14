using System.Collections;
using UnityEngine;
using UnityEngine.TestTools;

namespace Blackjack.PlayTests
{
    /// <summary>One screenshot per scenario (every screen, table state and dialog), named after it, in <c>BJ_SHOTS</c>.</summary>
    public class ScenarioShots
    {
        [UnityTest, NUnit.Framework.Timeout(1800000)]
        public IEnumerator Capture_everyScenario()
        {
            foreach (var scenario in Scenarios.All)
            {
                var run = ScenarioRun.Start(scenario);
                yield return Shots.Capture(run.Stage, scenario.Name);
                run.Stop();
                yield return null;
            }
            Debug.Log($"Scenario shots written to {Shots.OutDir}");
        }
    }
}
