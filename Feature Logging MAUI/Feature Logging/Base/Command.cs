using System.Windows.Input;

namespace FeatureLogging.Base;

public class SimpleCommand(Action execute, Func<bool>? canExecute = null) : ICommand
{
    private readonly WeakEventManager weakEventManager = new();
    
    public event EventHandler? CanExecuteChanged
    {
        add => weakEventManager.AddEventHandler(value);
        remove => weakEventManager.RemoveEventHandler(value);
    }

    private readonly Action execute = execute ?? throw new ArgumentNullException(nameof(execute));
    private readonly Func<bool> canExecute = canExecute ?? (() => true);

    public bool CanExecute(object? sender) => canExecute();

    public void Execute(object? sender)
    {
        if (!CanExecute(sender))
        {
            return;
        }
        execute();
    }
}

public class SimpleCommandWithParameter(Action<object?> execute, Func<object?, bool>? canExecute = null) : ICommand
{
    private readonly WeakEventManager weakEventManager = new();

    public event EventHandler? CanExecuteChanged
    {
        add => weakEventManager.AddEventHandler(value);
        remove => weakEventManager.RemoveEventHandler(value);
    }

    private readonly Action<object?> execute = execute ?? throw new ArgumentNullException(nameof(execute));
    private readonly Func<object?, bool> canExecute = canExecute ?? (_ => true);

    public bool CanExecute(object? sender) => canExecute(sender);

    public void Execute(object? sender)
    {
        if (!CanExecute(sender))
        {
            return;
        }
        execute(sender);
    }
}
