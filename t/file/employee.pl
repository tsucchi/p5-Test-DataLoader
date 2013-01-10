+{
    # table_name can be omitted. In this case, filename(except .pl) is used for table_name.
    #table_name => 'employee',
    data => {
        1 => {
            id   => 123,
            name => 'aaa',
        },
    },
    unique_keys => ['id'],
}
