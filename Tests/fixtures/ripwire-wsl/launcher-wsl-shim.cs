using System;
using System.Collections.Generic;
using System.IO;
using System.Diagnostics;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Script.Serialization;

internal sealed class LaunchRecord
{
    public string[] Arguments { get; set; }
    public Dictionary<string, string> Environment { get; set; }
}

internal static class Program
{
    private static readonly string[] RecordedEnvironment = {
        "LAUNCHER_PARENT_SENTINEL", "GIT_CONFIG_COUNT", "GIT_CONFIG_KEY_0",
        "GIT_CONFIG_VALUE_0", "GIT_CONFIG_KEY_1", "GIT_CONFIG_VALUE_1",
        "GIT_CONFIG_KEY_2", "GIT_CONFIG_VALUE_2",
        "GIT_DIR", "GIT_WORK_TREE", "GIT_COMMON_DIR",
        "GIT_OPTIONAL_LOCKS", "RIPWIRE_BIN", "RIPWIRE_WSL_OPERATION",
        "RIPWIRE_WSL_DIAGNOSTIC", "TMPDIR", "XDG_CACHE_HOME", "WSLENV"
    };

    private static string Translate(string value)
    {
        var bytes = Encoding.UTF8.GetBytes(value);
        var result = new StringBuilder("/translated/");
        foreach (var valueByte in bytes) result.Append(valueByte.ToString("x2"));
        return result.ToString();
    }

    private static byte[] ReadBytes(string name)
    {
        var value = Environment.GetEnvironmentVariable(name);
        return String.IsNullOrEmpty(value) ? new byte[0] : Convert.FromBase64String(value);
    }

    private static string QuoteArgument(string value)
    {
        if (value.Length != 0 && value.IndexOfAny(new[] { ' ', '\t', '\n', '\v', '"' }) < 0)
            return value;
        var quoted = new StringBuilder("\"");
        var backslashes = 0;
        foreach (var character in value)
        {
            if (character == '\\')
            {
                backslashes++;
            }
            else if (character == '"')
            {
                quoted.Append('\\', backslashes * 2 + 1);
                quoted.Append(character);
                backslashes = 0;
            }
            else
            {
                quoted.Append('\\', backslashes);
                quoted.Append(character);
                backslashes = 0;
            }
        }
        quoted.Append('\\', backslashes * 2);
        quoted.Append('"');
        return quoted.ToString();
    }

    private static int RunChild(string fileName, IList<string> arguments)
    {
        var start = new ProcessStartInfo {
            FileName = fileName,
            Arguments = String.Join(" ", new List<string>(arguments).ConvertAll(QuoteArgument).ToArray()),
            UseShellExecute = false,
            RedirectStandardOutput = true,
            RedirectStandardError = true
        };
        var process = new Process { StartInfo = start };
        process.Start();
        var stdout = process.StandardOutput.BaseStream.CopyToAsync(Console.OpenStandardOutput());
        var stderr = process.StandardError.BaseStream.CopyToAsync(Console.OpenStandardError());
        process.WaitForExit();
        Task.WaitAll(stdout, stderr);
        return process.ExitCode;
    }

    private static void WriteRecord(string path, string[] args)
    {
        if (String.IsNullOrEmpty(path)) return;
        var values = new Dictionary<string, string>(StringComparer.Ordinal);
        foreach (var name in RecordedEnvironment)
            values[name] = Environment.GetEnvironmentVariable(name);
        var record = new LaunchRecord { Arguments = args, Environment = values };
        File.WriteAllText(path, new JavaScriptSerializer().Serialize(record), new UTF8Encoding(false));
    }

    private static int RunWsl(string[] args)
    {
        var countPath = Environment.GetEnvironmentVariable("LAUNCHER_SHIM_COUNT");
        if (!String.IsNullOrEmpty(countPath)) File.AppendAllText(countPath, "start\n");
        for (var index = 0; index + 1 < args.Length; index++)
        {
            if (args[index] == "--exec" && args[index + 1] == "wslpath")
            {
                var mode = Environment.GetEnvironmentVariable("LAUNCHER_SHIM_WSLPATH_MODE");
                if (mode == "fail")
                {
                    Console.Error.Write("configured wslpath failure");
                    return 41;
                }
                if (mode == "invalid")
                {
                    Console.Out.Write("relative/not-absolute\n");
                    return 0;
                }
                Console.Out.Write(Translate(args[args.Length - 1]) + "\n");
                return 0;
            }
        }

        WriteRecord(Environment.GetEnvironmentVariable("LAUNCHER_SHIM_RECORD"), args);
        if (Environment.GetEnvironmentVariable("LAUNCHER_CHAIN_ENABLED") == "1")
        {
            var cd = Array.IndexOf(args, "--cd");
            var bash = Array.IndexOf(args, "/bin/bash");
            if (cd < 0 || cd + 1 >= args.Length || bash < 0 || bash + 2 >= args.Length ||
                args[bash + 1] != "--")
                return 91;
            Environment.SetEnvironmentVariable("LAUNCHER_CHAIN_EXPECTED_ROOT", args[cd + 1]);
            var bootstrapArguments = new List<string>();
            for (var index = bash + 3; index < args.Length; index++)
                bootstrapArguments.Add(args[index]);
            return RunChild(Path.Combine(
                Environment.GetEnvironmentVariable("LAUNCHER_CHAIN_BIN_ROOT"),
                "fake-bootstrap.exe"), bootstrapArguments);
        }
        return WriteConfiguredStreams();
    }

    private static int WriteConfiguredStreams()
    {
        var stdout = ReadBytes("LAUNCHER_SHIM_STDOUT_BASE64");
        var stderr = ReadBytes("LAUNCHER_SHIM_STDERR_BASE64");
        if (Environment.GetEnvironmentVariable("LAUNCHER_SHIM_CONCURRENT") == "1")
        {
            var outputThread = new Thread(() => Console.OpenStandardOutput().Write(stdout, 0, stdout.Length));
            var errorThread = new Thread(() => Console.OpenStandardError().Write(stderr, 0, stderr.Length));
            outputThread.Start();
            errorThread.Start();
            outputThread.Join();
            errorThread.Join();
        }
        else
        {
            Console.OpenStandardOutput().Write(stdout, 0, stdout.Length);
            Console.OpenStandardError().Write(stderr, 0, stderr.Length);
        }

        int exitCode;
        return Int32.TryParse(Environment.GetEnvironmentVariable("LAUNCHER_SHIM_EXIT"), out exitCode)
            ? exitCode : 0;
    }

    private static int RunBootstrap(string[] args)
    {
        var expectedRoot = Environment.GetEnvironmentVariable("LAUNCHER_CHAIN_EXPECTED_ROOT");
        if (args.Length < 2 || args[0] != "--" || args[1] != expectedRoot ||
            Environment.GetEnvironmentVariable("GIT_WORK_TREE") != expectedRoot)
            return 92;
        int count;
        if (!Int32.TryParse(Environment.GetEnvironmentVariable("GIT_CONFIG_COUNT"), out count))
            return 93;
        for (var index = 0; index < count; index++)
        {
            if (Environment.GetEnvironmentVariable("GIT_CONFIG_KEY_" + index) == null ||
                Environment.GetEnvironmentVariable("GIT_CONFIG_VALUE_" + index) == null)
                return 94;
        }
        Environment.SetEnvironmentVariable("GIT_CONFIG_KEY_" + count, "diff.autoRefreshIndex");
        Environment.SetEnvironmentVariable("GIT_CONFIG_VALUE_" + count, "false");
        count++;
        Environment.SetEnvironmentVariable("GIT_CONFIG_KEY_" + count, "core.fsmonitor");
        Environment.SetEnvironmentVariable("GIT_CONFIG_VALUE_" + count, "false");
        Environment.SetEnvironmentVariable("GIT_CONFIG_COUNT", (count + 1).ToString());
        var ripwireArguments = new List<string>();
        for (var index = 1; index < args.Length; index++) ripwireArguments.Add(args[index]);
        return RunChild(Path.Combine(
            Environment.GetEnvironmentVariable("LAUNCHER_CHAIN_BIN_ROOT"),
            "fake-ripwire.exe"), ripwireArguments);
    }

    private static int RunRipwire(string[] args)
    {
        WriteRecord(Environment.GetEnvironmentVariable("LAUNCHER_CHAIN_ENDPOINT_RECORD"), args);
        return WriteConfiguredStreams();
    }

    public static int Main(string[] args)
    {
        var executable = Path.GetFileNameWithoutExtension(
            Process.GetCurrentProcess().MainModule.FileName).ToLowerInvariant();
        if (executable == "fake-bootstrap") return RunBootstrap(args);
        if (executable == "fake-ripwire") return RunRipwire(args);
        return RunWsl(args);
    }
}
