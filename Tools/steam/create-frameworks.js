function createFrameworks()
{
    return create(Array.concat.apply(arguments, ["-f"]));
}