package tools
{
    import mx.utils.StringUtil;

    public function isEmpty(str:String):Boolean
    {
        return str == null || StringUtil.trim(str) == "";
    }
}
